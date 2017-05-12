use 5.008;
use strict;
use warnings;

package Hook::Modular;
BEGIN {
  $Hook::Modular::VERSION = '1.101050';
}
# ABSTRACT: Making pluggable applications easy
use Encode ();
use Data::Dumper;
use File::Copy;
use File::Spec;
use File::Basename;
use File::Find::Rule ();    # don't import rule()!
use Hook::Modular::ConfigLoader;
use UNIVERSAL::require;
use parent qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw(conf plugins_path cache));
use constant CACHE_CLASS           => 'Hook::Modular::Cache';
use constant CACHE_PROXY_CLASS     => 'Hook::Modular::CacheProxy';
use constant PLUGIN_NAMESPACE      => 'Hook::Modular::Plugin';
use constant SHOULD_REWRITE_CONFIG => 0;

# Need an array, because rules live in Hook::Module::Rule::* as well as rule
# namespace of your subclassed program. We don't need such an array for
# PLUGIN_NAMESPACE because we don't have any plugins under
# 'Hook::Modular::Plugin::*'.
my @rule_namespaces = ('Hook::Modular::Rule');

sub add_to_rule_namespaces {
    my ($self, @ns) = @_;
    push @rule_namespaces => @ns;
}

sub rule_namespaces {
    wantarray ? @rule_namespaces : \@rule_namespaces;
}
my $context;
sub context { $context }
sub set_context { $context = $_[1] }

sub new {
    my ($class, %opt) = @_;
    my $self = bless {
        conf          => {},
        plugins_path  => {},
        plugins       => [],
        rewrite_tasks => [],
    }, $class;
    my $loader = Hook::Modular::ConfigLoader->new;
    my $config = $loader->load($opt{config}, $self);
    $loader->load_include($config);
    $self->{conf} = $config->{global};
    $self->{conf}{log} ||= { level => 'debug' };
    $self->{conf}{plugin_namespace} ||= $self->PLUGIN_NAMESPACE;

    # don't use ||= here, as we are dealing with boolean values, so "0" is a
    # possible value.
    unless (defined $self->{conf}{should_rewrite_config}) {
        $self->{conf}{should_rewrite_config} = $self->SHOULD_REWRITE_CONFIG;
    }
    if (my $ns = $self->{conf}{rule_namespaces}) {
        $ns = [$ns] unless ref $ns eq 'ARRAY';
        $self->add_to_rule_namespaces(@$ns);
    }
    if (eval { require Term::Encoding }) {
        $self->{conf}{log}{encoding} ||= Term::Encoding::get_encoding();
    }
    Hook::Modular->set_context($self);
    $loader->load_recipes($config);
    $self->load_cache($opt{config});
    $self->load_plugins(@{ $config->{plugins} || [] });
    $self->rewrite_config
      if $self->{conf}{should_rewrite_config} && @{ $self->{rewrite_tasks} };

    # for subclasses
    $self->init;
    $self;
}
sub init { }

sub bootstrap {
    my $class = shift;
    my $self  = $class->new(@_);
    $self->run;
    $self;
}

sub add_rewrite_task {
    my ($self, @stuff) = @_;
    push @{ $self->{rewrite_tasks} }, \@stuff;
}

sub rewrite_config {
    my $self = shift;
    unless ($self->{config_path}) {
        $self->log(
            warn => "config is not loaded from file. Ignoring rewrite tasks.");
        $self->{trace}{ignored_rewrite_config}++;    # for tests
        return;
    }
    open my $fh, '<', $self->{config_path}
      or $self->error("$self->{config_path}: $!");
    my $data = join '', <$fh>;
    close $fh;
    my $count;

    # xxx this is a quick hack: It should be a YAML roundtrip maybe
    for my $task (@{ $self->{rewrite_tasks} }) {
        my ($key, $old_value, $new_value) = @$task;
        if ($data =~ s/^(\s+$key:\s+)\Q$old_value\E[ \t]*$/$1$new_value/m) {
            $count++;
        } else {
            $self->log(
                error => "$key: $old_value not found in $self->{config_path}");
        }
    }
    if ($count) {
        File::Copy::copy($self->{config_path}, $self->{config_path} . '.bak');
        open my $fh, '>', $self->{config_path}
          or return $self->log(error => "$self->{config_path}: $!");
        print $fh $data;
        close $fh;
        $self->log(info =>
              "Rewrote $count password(s) and saved to $self->{config_path}");
    }
}

sub load_cache {
    my ($self, $config) = @_;

    # cache is auto-vivified but that's okay
    unless ($self->{conf}{cache}{base}) {

        # use config filename as a base directory for cache
        my $base = (basename($config) =~ /^(.*?)\.yaml$/)[0] || 'config';
        my $dir = $base eq 'config' ? ".$0" : ".$0-$base";
        $self->{conf}{cache}{base} ||=
          File::Spec->catfile($self->home_dir, $dir);
    }
    my $cache_class = $self->CACHE_CLASS;
    $cache_class->require or die $@;
    $self->cache($cache_class->new($self->{conf}{cache}));
}

sub home_dir {
    eval { require File::HomeDir };
    return $@ ? $ENV{HOME} : File::HomeDir->my_home;
}

sub load_plugins {
    my ($self, @plugins) = @_;
    my $plugin_path = $self->conf->{plugin_path} || [];
    $plugin_path = [$plugin_path] unless ref $plugin_path;
    for my $path (@$plugin_path) {
        opendir my $dir, $path or do {
            $self->log(warn => "$path: $!");
            next;
        };
        while (my $ent = readdir $dir) {
            next if $ent =~ /^\./;
            $ent = File::Spec->catfile($path, $ent);
            if (-f $ent && $ent =~ /\.pm$/) {
                $self->add_plugin_path($ent);
            } elsif (-d $ent) {
                my $lib = File::Spec->catfile($ent, "lib");
                if (-e $lib && -d _) {
                    $self->log(debug => "Add $lib to INC path");
                    unshift @INC, $lib;
                } else {
                    my $rule = File::Find::Rule->new;
                    $rule->file;
                    $rule->name('*.pm');
                    my @modules = $rule->in($ent);
                    for my $module (@modules) {
                        $self->add_plugin_path($module);
                    }
                }
            }
        }
    }
    for my $plugin (@plugins) {
        $self->load_plugin($plugin) unless $plugin->{disable};
    }
}

sub add_plugin_path {
    my ($self, $file) = @_;
    my $pkg = $self->extract_package($file)
      or die "Can't find package from $file";
    $self->plugins_path->{$pkg} = $file;
    $self->log(debug => "$file is added as a path to plugin $pkg");
}

sub extract_package {
    my ($self, $file) = @_;
    my $ns = $self->{conf}{plugin_namespace} . '::';
    open my $fh, '<', $file or die "$file: $!";
    while (<$fh>) {
        /^package ($ns.*?);/ and return $1;
    }
    return;
}

sub autoload_plugin {
    my ($self, $plugin) = @_;
    unless ($self->is_loaded($plugin->{module})) {
        $self->load_plugin($plugin);
    }
}

sub is_loaded {
    my ($self, $stuff) = @_;
    my $sub =
      ref $stuff && ref $stuff eq 'Regexp'
      ? sub { $_[0] =~ $stuff }
      : sub { $_[0] eq $stuff };
    my $ns = $self->{conf}{plugin_namespace} . '::';
    for my $plugin (@{ $self->{plugins} }) {
        my $module = ref $plugin;
        $module =~ s/^$ns//;
        return 1 if $sub->($module);
    }
    return;
}

sub load_plugin {
    my ($self, $config) = @_;
    my $ns     = $self->{conf}{plugin_namespace} . '::';
    my $module = delete $config->{module};
    if ($module !~ s/^\+//) {
        $module =~ s/^$ns//;
        $module = $ns . $module;
    }
    if ($module->isa($self->{conf}{plugin_namespace})) {
        $self->log(debug => "$module is loaded elsewhere ... maybe .t script?");
    } elsif (my $path = $self->plugins_path->{$module}) {
        $path->require or die $@;
    } else {
        $module->require or die $@;
    }
    $self->log(info => "plugin $module loaded.");
    my $plugin            = $module->new($config);
    my $cache_proxy_class = $self->CACHE_PROXY_CLASS;
    $cache_proxy_class->require or die $@;
    $plugin->cache($cache_proxy_class->new($plugin, $self->cache));
    $plugin->register($self);
    push @{ $self->{plugins} }, $plugin;
}

sub register_hook {
    my ($self, $plugin, @hooks) = @_;
    while (my ($hook, $callback) = splice @hooks, 0, 2) {

        # set default rule_hook $hook to $plugin
        $plugin->rule_hook($hook) unless $plugin->rule_hook;
        push @{ $self->{hooks}{$hook} },
          +{callback => $callback,
            plugin   => $plugin,
          };
    }
}

sub run_hook {
    my ($self, $hook, $args, $once, $callback) = @_;
    my @ret;
    $self->log(debug => "run_hook $hook");
    for my $action (@{ $self->{hooks}{$hook} }) {
        my $plugin = $action->{plugin};
        $self->log(debug => sprintf('--> plugin %s', ref $plugin));
        if ($plugin->rule->dispatch($plugin, $hook, $args)) {
            $self->log(debug => "----> running action");
            my $ret = $action->{callback}->($plugin, $self, $args);
            $callback->($ret) if $callback;
            if ($once) {
                return $ret if defined $ret;
            } else {
                push @ret, $ret;
            }
        } else {
            push @ret, undef;
        }
    }
    return if $once;
    return @ret;
}

sub run_hook_once {
    my ($self, $hook, $args, $callback) = @_;
    $self->run_hook($hook, $args, 1, $callback);
}

sub run_main {
    my $self = shift;
    $self->run_hook('plugin.init');
    $self->run;
    $self->run_hook('plugin.finalize');
    Hook::Modular->set_context(undef);
    $self;
}
sub run { }

sub log {
    my ($self, $level, $msg, %opt) = @_;
    return unless $self->should_log($level);

    # hack to get the original caller as Plugin or Rule
    my $caller = $opt{caller};
    unless ($caller) {
        my $i = 0;
        while (my $c = caller($i++)) {
            last if $c !~ /Plugin|Rule/;
            $caller = $c;
        }
        $caller ||= caller(0);
    }
    chomp($msg);
    if ($self->conf->{log}->{encoding}) {
        $msg = Encode::decode_utf8($msg) unless utf8::is_utf8($msg);
        $msg = Encode::encode($self->conf->{log}->{encoding}, $msg);
    }
    warn "$caller [$level] $msg\n";
}
my %levels = (
    debug => 0,
    warn  => 1,
    info  => 2,
    error => 3,
);

sub should_log {
    my ($self, $level) = @_;
    $levels{$level} >= $levels{ $self->conf->{log}->{level} };
}

sub error {
    my ($self, $msg) = @_;
    my ($caller, $filename, $line) = caller(0);
    chomp($msg);
    die "$caller [fatal] $msg at file $filename line $line\n";
}

sub dumper {
    my ($self, $stuff) = @_;
    local $Data::Dumper::Indent = 1;
    $self->log(debug => Dumper $stuff);
}
1;


=pod

=for stopwords conf

=for test_synopsis 1;
__END__

=head1 NAME

Hook::Modular - Making pluggable applications easy

=head1 VERSION

version 1.101050

=head1 SYNOPSIS

In C<some_config.yaml>

  global:
    log:
      level: error
    cache:
      base: /tmp/test-hook-modular
    # plugin_namespace: My::Test::Plugin
  
  plugins:
    - module: Some::Printer
      config:
        indent: 4
        indent_char: '*'
        text: 'this is some printer'

here is the plugin:

  package My::Test::Plugin::Some::Printer;
  use warnings;
  use strict;
  use parent 'Hook::Modular::Plugin';
  
  sub register {
      my ($self, $context) = @_;
      $context->register_hook($self,
        'output.print' => $self->can('do_print'));
  }
  
  sub do_print { ... }

And this is C<some_app.pl>

  use parent 'Hook::Modular';

  use constant PLUGIN_NAMESPACE => 'My::Test::Plugin';

  sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    ...
    $self->run_hook('output.print', ...);
    ...
  }

  main->bootstrap(config => $config_filename);

But also see L<Hook::Modular::Builder> for a domain-specific language to build
a configuration.

=head1 DESCRIPTION

Hook::Modular makes writing pluggable applications easy. Use a config file to
specify which plugins you want and to pass options to those plugins. The
program to support those plugin then subclasses Hook::Modular and bootstraps
itself. This causes the plugins to be loaded and registered. This gives each
plugin the chance to register callbacks for any or all hooks the program
offers. The program then runs the hooks in the order it desires. Each time a
hook is run, all the callbacks the plugins have registered with this
particular hook are run in order.

Hook::Modular does more than just load and call plugins, however. It also
supports the following concepts:

=over 4

=item Cache

Plugins can cache their settings. Cached items can also expire after a given
time.

=item Crypt

Hook::Lexwrap can go over your config file and encrypt any passwords it finds
(as determined by the key C<password>). It will then rewrite the config file
and make a backup of the original file. Encrypting and rewriting is turned off
by default, but subclasses can enable it, or you can enable it from a config
file itself.

At the moment, encrypting is rather basic: The passwords are only turned into
base64.

=item Rules

Hook::Modular supports rule-based dispatch of plugins.

=back

=head1 METHODS

=head2 new

  my $obj = Hook::Modular->new(config => $config_file_name);

Creates a new object and initializes it. The arguments are passed as a named
hash. Valid argument keys:

=over 4

=item C<config>

Reads or sets the global configuration.

If the value is a simple string, it is interpreted as a filename. If the file
is readable, it is loaded as YAML. If the filename is C<->, the configuration
is read from STDIN.

If the value is a scalar reference, the dereferenced value is assumed to be
YAML and is loaded.

If the value is a hash reference, the configuration is cloned from that hash
reference.

Also see L<Hook::Modular::Builder> for a domain-specific language to build a
configuration.

=back

The constructor also sets the application-wide configuration, which can be
accessed using C<conf()>, to the C<global> part of the configuration data that
has been passed to the constructor. This configuration is then augmented in
various ways:

=over 4

=item C<log level>

  my $level = $self->conf->{log}{level}

The log level is set to C<debug>, if it hasn't been set by the configuration
data already.

In the config file, you can specify it this way:

  global:
    log:
      level: info

=item C<log encoding>

  my $encoding = $self->conf->{log}{encoding}

The log encoding is set to the current terminal's encoding, if it hasn't been
set by the configuration data already.

In the config file, you can specify it this way:

  global:
    log:
      level: info

=item C<plugin_namespace>

  my $ns = $self->conf->{plugin_namespace};

The default plugin namespace is set to whatever the class defines as the
C<PLUGIN_NAMESPACE> constant, if the configuration data hasn't set it already.
See the documentation of C<PLUGIN_NAMESPACE> for details.

=item C<should_rewrite_config>

  my $should_rewrite_config = $self->conf->{should_rewrite_config};

If the configuration data hasn't set it already to either 0 or 1, config file
rewriting is turned off. See the documentation of C<SHOULD_REWRITE_CONFIG> for
details.

=item C<rule_namespaces>

If the config file specifies any rule namespaces, they are added to the
default rule namespaces. See the documentation of C<add_to_rule_namespaces()>
for details.

=back

=head2 context, set_context

  my $context = $self->context;
  $self->set_context($context);

Gets and sets (respectively) the global context. It is singular; each program
has only one context. This can be used to communicate between the plugins.

=head2 conf

  my %conf = $self->conf;
  my $plugin_path = $self->conf->{plugin_path} || [];
  $self->conf->{log}{level} = 'debug';

Returns a hash that has the application-wide configuration. It is set during
C<new()> from the C<global> section of the configuration data and augmented
with various other settings.

=head2 PLUGIN_NAMESPACE

  package My::TestApp;
  use parent 'Hook::Modular';
  use constant PLUGIN_NAMESPACE => 'My::Test::Plugin';

A constant that specifies the namespace that is prepended to plugin names
found in the configuration. Defaults to C<Hook::Modular::Plugin>. Subclasses
can and probably should override this value. For example, if the plugin
namespace is set to C<My::Test::Plugin> and the config file specifies a plugin
with the name C<Some::Printer>, we will try to load
C<My:::Test::Plugin::Some::Printer>.

In the config file, you can specify it this way:

  global:
    plugin_namespace: My::Test::Plugin

=head2 SHOULD_REWRITE_CONFIG

  package My::TestApp;
  use parent 'Hook::Modular';
  use constant SHOULD_REWRITE_CONFIG => 1;

Hook::Modular can rewrite your config file, for example, to turn passwords
into encrypted forms so they are not easily readable in the plain text. This
behaviour is turned off by default, but the config file, or a subclass of
Hook::Modular, can turn it on. In a config file, specify it this way:

In the config file, you can specify it this way:

  global:
    should_rewrite_config: 1

=head2 add_to_rule_namespace

  $self->add_to_rule_namespaces(
    qw/Some::Rule::Namespace Other::Rule::Namespace/);

Hook::Modular supports multiple rule namespace, that is, package prefixes that
are used when looking for rule classes. The reason to allow multiple rule
namespace is that Hook::Modular has some rules, and your subclass might well
define its own rules, so Hook::Modular needs to know which package it might
find rules in.

There is only one list of rule namespace per program. To add to rule
namespaces in your program, don't access C<conf()> directly, but use the
proper class methods to do so: C<add_to_rule_namespaces()> and
C<rule_namespaces()>.

You can add to rule namespaces using the config file like this:

  global:
    rule_namespaces:
      - Some::Thing::Rule
      - Other::Thing::Rule

or, if you only want to add one rule namespace:

  global:
    rule_namespaces: Some::Thing::Rule

=head2 rule_namespaces

  my @ns = $self->rule_namespaces;

Returns the list of rule namespaces. See the documentation of
C<add_to_rule_namespaces> for details.

=head2 add_plugin_path

FIXME

=head2 add_rewrite_task

FIXME

=head2 add_to_rule_namespaces

FIXME

=head2 autoload_plugin

FIXME

=head2 dumper

FIXME

=head2 error

FIXME

=head2 extract_package

FIXME

=head2 home_dir

FIXME

=head2 init

FIXME

=head2 is_loaded

FIXME

=head2 load_cache

FIXME

=head2 load_plugin

FIXME

=head2 load_plugins

FIXME

=head2 register_hook

FIXME

=head2 rewrite_config

FIXME

=head2 run

FIXME

=head2 run_hook

FIXME

=head2 run_hook_once

FIXME

=head2 run_main

FIXME

=head2 should_log

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Hook-Modular>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Hook-Modular/>.

The development version lives at
L<http://github.com/hanekomu/Hook-Modular/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

  Marcel Gruenauer <marcel@cpan.org>
  Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

