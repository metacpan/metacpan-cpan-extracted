use 5.008;
use strict;
use warnings;

package Hook::Modular::Plugin;
BEGIN {
  $Hook::Modular::Plugin::VERSION = '1.101050';
}
# ABSTRACT: Base class for plugins
use File::Find::Rule ();    # don't import rule()
use File::Spec;
use File::Basename;
use Hook::Modular;
use Hook::Modular::Crypt;
use Hook::Modular::Rule;
use Hook::Modular::Rules;
use Scalar::Util qw(blessed);
use parent qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw(rule_hook cache));

sub new {
    my ($class, $opt) = @_;
    my $self = bless {
        conf    => $opt->{config}  || {},
        rule    => $opt->{rule},
        rule_op => $opt->{rule_op} || 'AND',
        rule_hook => '',
        meta      => {},
    }, $class;
    $self->init;
    $self;
}

sub init {
    my $self = shift;
    if (my $rule = $self->{rule}) {
        $rule = [$rule] if ref $rule eq 'HASH';
        my $op = $self->{rule_op};
        $self->{rule} = Hook::Modular::Rules->new($op, @$rule);
    } else {
        $self->{rule} = Hook::Modular::Rule->new({ module => 'Always' });
    }
    $self->walk_config_encryption
      if Hook::Modular->context->{conf}{should_rewrite_config};
}
sub conf { $_[0]->{conf} }
sub rule { $_[0]->{rule} }

sub walk_config_encryption {
    my $self = shift;
    my $conf = $self->conf;
    $self->do_walk($conf);
}

sub do_walk {
    my ($self, $data) = @_;
    return unless defined($data) && ref $data;
    if (ref $data eq 'HASH') {
        for my $key (keys %$data) {
            if ($key =~ /password/) {
                $self->decrypt_config($data, $key);
            }
            $self->do_walk($data->{$key});
        }
    } elsif (ref $data eq 'ARRAY') {
        $self->do_walk($_) for @$data;
    }
}

sub decrypt_config {
    my ($self, $data, $key) = @_;
    my $decrypted = Hook::Modular::Crypt->decrypt($data->{$key});
    if ($decrypted eq $data->{$key}) {
        Hook::Modular->context->add_rewrite_task($key, $decrypted,
            Hook::Modular::Crypt->encrypt($decrypted, 'base64'));
    } else {
        $data->{$key} = $decrypted;
    }
}

sub dispatch_rule_on {
    my ($self, $hook) = @_;
    $self->rule_hook && $self->rule_hook eq $hook;
}

sub class_id {
    my $self = shift;
    my $ns   = Hook::Modular->context->{conf}{plugin_namespace};
    my $pkg  = ref($self) || $self;
    $pkg =~ s/$ns//;
    my @pkg = split /::/, $pkg;
    return join '-', @pkg;
}

# subclasses may overload to avoid cache sharing
sub plugin_id {
    my $self = shift;
    $self->class_id;
}

sub assets_dir {
    my $self    = shift;
    my $context = Hook::Modular->context;
    if ($self->conf->{assets_path}) {
        return $self->conf->{assets_path};    # look at config:assets_path first
    }
    my $assets_base = $context->conf->{assets_path} ||   # or global:assets_path
      File::Spec->catfile($FindBin::Bin, "assets")
      ;    # or "assets" under current script
    return File::Spec->catfile($assets_base, "plugins", $self->class_id,);
}

sub log {
    my $self = shift;
    Hook::Modular->context->log(@_, caller => ref $self);
}

sub load_assets {
    my ($self, $rule, $callback) = @_;
    unless (blessed($rule) && $rule->isa('File::Find::Rule')) {
        $rule = File::Find::Rule->name($rule);
    }

    # ignore .svn directories
    $rule->or($rule->new->directory->name('.svn')->prune->discard, $rule->new,);

    # $rule isa File::Find::Rule
    for my $file ($rule->in($self->assets_dir)) {
        my $base = File::Basename::basename($file);
        $callback->($file, $base);
    }
}
1;


__END__
=pod

=for stopwords conf

=for test_synopsis 1;
__END__

=head1 NAME

Hook::Modular::Plugin - Base class for plugins

=head1 VERSION

version 1.101050

=head1 SYNOPSIS

Here is C<some_config.yaml>:

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

=head1 DESCRIPTION

NOTE: This is a documentation in progress. Not all features or quirks of this
class have been documented yet.

This is the base class for plugins. All plugins have to subclass this class.

If your plugin is in a different namespace than C<Hook::Modular::Plugin::>
then your main program - the one that subclasses L<Hook::Modular> and calls
C<bootstrap()> - has to redefine the C<PLUGIN_NAMESPACE> constant as shown in
the synopsis.

=head1 METHODS

=head2 new

Creates a new object and initializes it. Normally you don't call this method
yourself, however. Instead, L<Hook::Modular> calls it when loading the plugins
specified in the configuration.

The arguments are passed as a named hash. Valid argument keys:

=over 4

=item C<conf>

The plugin's own configuration, taken straight from the configuration. It has to be a hash of scalars, or hash of hashes or the like. See L</"PLUGIN CONFIGURATION"> for details.

=item C<rule>

Specifies the rule to be used for this plugin's dispatch. See L</"RULES">.

=item C<rule_op>

Specifies the rule operator to be used for this plugin's dispatch. See
L</"RULES">.

=back

After accessors have been set, any hash keys named C<password> within the
plugin's configuration are decrypted. If unencrypted passwords are found, they
can be encrypted. At the moment, this encryption is more a proof-of-concept,
as the only encryption supported isn't even an encryption, just base64
encoding.

This encryption and decryption is only happening if your main class, the one
subclassing Hook::Modular, says it should. See C<SHOULD_REWRITE_CONFIG> in
L<Hook::Modular> for details.

=head2 conf

Returns the plugin's configuration hash.

=head2 rule

Returns the plugin's rule settings.

=head2 assets_dir

FIXME

=head2 class_id

FIXME

=head2 decrypt_config

FIXME

=head2 dispatch_rule_on

FIXME

=head2 do_walk

FIXME

=head2 init

FIXME

=head2 load_assets

FIXME

=head2 log

FIXME

=head2 plugin_id

FIXME

=head2 walk_config_encryption

FIXME

=head1 PLUGIN CONFIGURATION

The plugin's configuration can be accessed using C<conf()>. It is a hash whose
values can be anything you like. There are a few standard keys with predefined
meanings:

=over 4

=item C<disable>

  plugins:
    - module: Some::Printer
      disable: 1
      config:
        ...

If this key is set to a true value in the plugin's configuration, the plugin
is not even loaded. This is useful for temporarily disabling plugins during
debugging.

=item C<assets_path>

  plugins:
    - module: Some::Printer
      assets_path: /path/to/assets/dir
      config:
        ...

Specifies the directory in which this particular plugin's assets can be found.
See L</"ASSETS">

=back

=head1 RULES

You can control whether a particular plugin is dispatched by setting rules in
its configuration.

  plugins:
    - module: Some::Printer
      rule:
        module: Deduped
        path: /path/to/depuped/file.db
      config:
        ...

If a rule is specified on a plugin, it is being called before a hook is run.
If the rule does not veto the dispatch, the hook is run.

In the example above, the current rule namespaces (see L<Hook::Modular>) are
searched for a class C<Deduped> and the rule config (in this case, a path) is
given to the rule. The rule is then asked whether the hook should run. See
L<Hook::Modular::Rule> for details.

It is possible to specify multiple rules along with a boolean operator that
says how the rule results are to be combined. Example:

  plugins:
    - module: Some::Printer
      rule:
        - module: Deduped
          path: /path/to/depuped/file.db
        - module: PhaseOfMoon
          phase: waxing
      rule_op: AND
      config:
        ...

In this example, the plugin is only run if both rules are ok with it, because
of the C<AND> rule operator.

=head1 ASSETS

Plugins can have assets. You can think of them as little sub-plugins that each
plugin can handle the way it wants. That is, apart from being able to find a
plugin's assets in a specific directory, there is not much more that
L<Hook::Modular::Plugin> enforces or provides.

One idea for assets may be little code snippets that you can just put in the
plugin's assets directory. They would be more involved than what you would
normally specify in a configuration file. So you could have the configuration
file point to one or more assets and the plugin could then load and eval these
assets and act on them.

There are three places that plugins can look for assets. If the plugin
configuration itself contains an C<assets_path> key, this directory is used
and no other directories are searched. Example:

  plugins:
    - module: Some::Printer
      assets_path: /path/to/assets/dir
      config:
        ...

If there is no plugin-specific C<assets_path> key, but there is an
C<assets_path> key in the C<global> part of the configuration, that directory
is used and no other directories are searched. Example:

  global:
    assets_path: /path/to/assets/dir

If neither a plugin-specific nor a global assets path is specified, an assets
directory in the same location as the current program, as determined by
C<$FindBin::Bin>, is used. The actual path used would be
C<$Bin/assets/plugins/Foo-Bar/>, where C<Foo-Bar> is that part of the plugin's
package name that comes after the plugin namespace, with double colons
converted to dashes. For example, if your plugin namespace is
C<My::Test::Plugin> and your plugin package name is
C<My::Test::Plugin::Some::Printer>, then the default assets directory would be
C<$Bin/assets/plugins/Some-Printer>.

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

