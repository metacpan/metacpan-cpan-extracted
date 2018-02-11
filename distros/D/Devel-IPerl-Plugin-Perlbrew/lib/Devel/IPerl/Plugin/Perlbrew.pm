package Devel::IPerl::Plugin::Perlbrew;

use strict;
use warnings;
use feature 'say';
use Symbol 'delete_package';
use constant DEBUG => $ENV{IPERL_PLUGIN_PERLBREW_DEBUG} ? 1 : 0;

use constant PERLBREW_CLASS => $ENV{IPERL_PLUGIN_PERLBREW_CLASS}
  ? $ENV{IPERL_PLUGIN_PERLBREW_CLASS}
  : 'App::perlbrew';

use constant PERLBREW_INSTALLED => eval 'use '. PERLBREW_CLASS.'; 1' ? 1 : 0;

our $VERSION = '0.03';

sub brew {
  my $self = shift;
  my %env  = %{$self->env || {}};
  my %save = ();
  for my $var(_filtered_env_keys(\%env)) {
    say STDERR "@$self{name} ", join " = ", $var, $env{$var} if DEBUG;
    $save{$var} = $ENV{$var} if exists $ENV{$var};
    $ENV{$var} = $env{$var};
  }
  if ($env{PERL5LIB}) {
    say STDERR join " = ", 'PERL5LIB', $env{'PERL5LIB'} if DEBUG;
    eval "use lib split ':', q[$env{PERL5LIB}];";
    warn $@ if $@; ## uncoverable branch true
  }
  return $self->saved(\%save);
}

sub env { return $_[0]{env}  if @_ == 1; $_[0]{env}  = $_[1]; $_[0]; }

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub name { return $_[0]{name} if @_ == 1; $_[0]{name} = $_[1]; $_[0]; }

sub register {
  my ($class, $iperl) = @_;

  my $domain = sub {
    my $instance = $_[0]->instance;
    return $instance->{'perlbrew_domain'} if @_ == 1;
    $instance->{'perlbrew_domain'} = $_[1];
    $instance;
  };

  $domain->($iperl, $ENV{'PERLBREW_HOME'});

  for my $name (qw{perlbrew}) {
    my $current = $class->new->name('@@@'); ## impossible name

    $iperl->helper($name => sub {
      my ($ip, $lib, $unload, $ret) = (shift, shift, shift || 0, -1);
      return $ret if not defined $lib;
      return $ret if 0 == PERLBREW_INSTALLED;

      my $new = $class->new->name($class->_make_name($lib));
      if ($current->unload($unload)->name ne $new->name) {
        my $pb = PERLBREW_CLASS->new();
        $pb->home($domain->($ip));
        $new->env({ $pb->perlbrew_env($new->name) });
        ## ensure the timing of the DESTROY, spoil
        undef($current = $current->spoil);
        $current = $new->brew;
      }
      return $new->success;
    });
  }

  for my $name (qw{list list_modules}) {
    $iperl->helper("perlbrew_$name" => sub {
      my ($ip, $ret) = (shift, -1);
      return $ret if 0 == PERLBREW_INSTALLED;
      my $pb = PERLBREW_CLASS->new();
      $pb->home($domain->($ip));
      local $App::perlbrew::PERLBREW_HOME = $pb->home
        if ($name eq 'list_modules');
      return $pb->run_command($name, @_);
    });
  }

  for my $name (qw{lib_create}) {
    $iperl->helper("perlbrew_$name" => sub {
      my ($ip, $lib, $ret) = (shift, shift, -1);
      return $ret if not defined $lib;
      return $ret if 0 == PERLBREW_INSTALLED;
      my $pb = PERLBREW_CLASS->new();
      $pb->home($domain->($ip));
      eval { $pb->run_command_lib_create($class->_make_name($lib)); };
      return $@ ? 0 : 1;
    });
  }

  $iperl->helper('perlbrew_domain' => sub {
    my ($ip, $dir) = (shift, shift);
    return $domain->($ip) unless $dir && -d $dir;
    return $domain->($ip, $dir)->{'perlbrew_domain'};
  });

  return 1;
}

sub saved { return $_[0]{saved}  if @_ == 1; $_[0]{saved}  = $_[1]; $_[0]; }

sub spoil {
  my $self = shift;
  my %env  = %{$self->env || {}};
  my %save = %{$self->saved || {}};
  for my $var(_filtered_env_keys(\%env)) {
    if (exists $save{$var}) {
      say STDERR "revert ", join " = ", $var, $save{$var} if DEBUG;
      $ENV{$var} = $save{$var};
    } else {
      say STDERR "unset ", $var if DEBUG;
      delete $ENV{$var};
    }
  }
  if ($env{PERL5LIB}) {
    say STDERR join " = ", 'PERL5LIB', $env{'PERL5LIB'} if DEBUG;
    eval "no lib split ':', q[$env{PERL5LIB}];";
    warn $@ if $@; ## uncoverable branch true
    if ($self->unload) {
      my $path_re = qr{\Q$env{PERL5LIB}\E};
      for my $module_path(keys %INC) {
        ## autosplit modules
        next if $module_path =~ m{\.(al|ix)$} && delete $INC{$module_path};
        ## global destruction ?
        next if not defined $INC{$module_path};
        ## FatPacked ?
        next if ref($INC{$module_path});
        ## Not part of this PERL5LIB
        next if $INC{$module_path} !~ m{^$path_re};
        ## translate to class_path
        (my $class = $module_path) =~ s{/}{::}g;
        $class =~ s/\.pm//;
        ## notify and unload
        say "unloading $class ($module_path) from $INC{$module_path}";
        _teardown( $class );
        delete $INC{$module_path};
      }
    }
  }
  # no need to revert again.
  return $self->env({})->saved({});
}

sub success { scalar(keys %{$_[0]->{env}}) ? 1 : 0; }

sub unload { return $_[0]{unload} if @_ == 1; $_[0]{unload} = $_[1]; $_[0]; }

sub _filtered_env_keys {
  return (sort grep { m/^PERL/i && $_ ne "PERL5LIB" } keys %{+pop});
}

sub _from_binary_path {
  say STDERR $^X if DEBUG;
  if ($^X =~ m{/perls/([^/]+)/bin/perl}) { return $1; }
  (my $v = $^V->normal) =~ s/v/perl-/;
  return $v;
}

sub _make_name {
  my ($class, $name, $current) =
    (shift, shift, $ENV{PERLBREW_PERL} || _from_binary_path());
  my ($perl, $lib) =
    split /\@/, ($name =~ m/\@/ || $name eq $current ? $name : "\@$name");
  $perl = $current;
  return $perl unless $lib;
  return join '@', $perl, $lib;
}

## from Mojo::Util
sub _teardown {
  return unless my $class = shift;
  # @ISA has to be cleared first because of circular references
  no strict 'refs';
  @{"${class}::ISA"} = ();
  delete_package $class;
}

sub DESTROY {
  my $self = shift;
  say STDERR "DESTROY $self @$self{name}" if DEBUG;
  $self->spoil;
  return ;
}

1;

=pod

=head1 NAME

Devel::IPerl::Plugin::Perlbrew - interact with L<perlbrew> in L<Jupyter|https://jupyter.org> IPerl kernel

=begin html

<!--- Travis --->
<a href="https://travis-ci.org/kiwiroy/Devel-IPerl-Plugin-Perlbrew">
  <img src="https://travis-ci.org/kiwiroy/Devel-IPerl-Plugin-Perlbrew.svg?branch=master"
       alt="Build Status" />
</a>

<!-- Coveralls -->
<a href='https://coveralls.io/github/kiwiroy/Devel-IPerl-Plugin-Perlbrew?branch=master'>
  <img src='https://coveralls.io/repos/github/kiwiroy/Devel-IPerl-Plugin-Perlbrew/badge.svg?branch=master'
       alt='Coverage Status' />
</a>

<!-- Kritika -->
<a href="https://kritika.io/users/kiwiroy/repos/6870682787977901/heads/master/">
  <img src="https://kritika.io/users/kiwiroy/repos/6870682787977901/heads/master/status.svg"
       alt="Kritika Analysis Status"/>
</a>

=end html

=head1 DESCRIPTION

In a shared server environment the Perl module needs of multiple users can be
met most easily with access to L<perlbrew> and the ability to install perl
modules under their own libraries. A user can generate a L<cpanfile> to
facilitate the creation of these libraries in a reproducible manner. At the
command line a typical workflow in such an environment might appear thus:

  perlbrew lib create perl-5.26.0@reproducible
  perlbrew use perl-5.26.0@reproducible
  ## assuming a cpanfile
  cpanm --installdeps .

During the analysis that utilises such codebases using a JupyterHub on the same
environment a user will wish to access these installed modules in a way that is
as simple as the command line and within the framework of a Jupyter notebook.

This plugin is designed to easily transition between command line and Jupyter
with similar syntax and little overhead.

=begin html

<p>There are some Jupyter notebooks in the <a href="./examples/">examples directory</a></p>

=end html

=head1 SYNOPSIS

  IPerl->load_plugin('Perlbrew') unless IPerl->can('perlbrew');
  IPerl->perlbrew_list();
  IPerl->perlbrew_list_modules();

  IPerl->perlbrew('perl-5.26.0@reproducible');

=head1 INSTALLATION AND REQUISITES

  ## install dependencies
  cpanm --installdeps --quiet .
  ## install
  cpanm .

If there are some issues with L<Devel::IPerl> installing refer to their
L<README.md|https://github.com/EntropyOrg/p5-Devel-IPerl>. The C<.travis.yml> in
this repository might provide sources of help.

L<App::perlbrew> is a requirement and it is B<suggested> that L<Devel::IPerl> is
deployed into a L<perlbrew> installed L<perl|perlbrew#COMMAND:-INSTALL> and call
the L</"perlbrew"> function to use each L<library|perlbrew#COMMAND:-LIB>.

=over 4

=item installing perlbrew

For a single user use case the recommended install proceedure at
L<https://perlbrew.pl> should be used. If installing for a shared environment
and JupyterHub, the following may act as a template.

  version=0.82
  mkdir -p /sw/perlbrew-$version
  export PERLBREW_ROOT=!$
  curl -L https://install.perlbrew.pl | bash

=item installing iperl

The kernel specification needs to be installed so that Jupyter can find it. This
is achieved thus:

  iperl --version

=item perlbrew-ise the kernel

The kernel specification should be updated to make the environment variables,
that L<App::perlbrew> relies on, available. Included in this dist is the command
C<perlbrewise-spec>.

  perlbrewise-spec

=back

=head1 IPerl Interface Method

=head2 register

Called by C<<< IPerl->load_plugin('Perlbrew') >>>.

=head1 REGISTERED METHODS

=head2 perlbrew

  # 1 - success
  IPerl->perlbrew('perl-5.26.0@reproducible');
  # 0 - it is already loaded
  IPerl->perlbrew('perl-5.26.0@reproducible');
  # -1 - no library specified
  IPerl->perlbrew();
  # 1 - success switching off reproducible and reverting to perl-5.26.0
  IPerl->perlbrew($ENV{'PERLBREW_PERL'});

This is identical to C<<< perlbrew use perl-5.26.0@reproducible >>> and will
switch any from any previous call. Returns C<1>, C<0> or C<-1> for I<success>,
I<no change> and I<error> respectively. A name for the library is required. To
revert to the I<"system"> or non-library version pass the value of
C<$ENV{PERLBREW_PERL}>.

  IPerl->perlbrew('perl-5.26.0@tutorial', 1);

The function takes a Boolean as an optional second argument. A I<true> value will
result in all the modules that were loaded during the activity of the previous
library to be unloaded using L<delete_package|Symbol>. The default value is
I<false> as setting is to true might expose the L<unexpected|Symbol#BUGS>
behaviour.

When using multiple L<perlbrew> libraries it may be possible to use modules from
both, although this is not a recommended use.

  IPerl->perlbrew('perl-5.26.0@tutorial');
  use Jupyter::Tutorial::Simple;
  ## run some code

  ## load @reproducible, but do not unload Jupyter::Tutorial::Simple
  IPerl->perlbrew('perl-5.26.0@reproducible', 0);
  use Bio::Taxonomy;
  ## ... more code, possibly using Jupyter::Tutorial::Simple

=head2 perlbrew_domain

B<This is experimental>.

  # /home/username/.perlbrew
  IPerl->perlbrew_domain;
  # /work/username/perlbrew-libs
  IPerl->perlbrew_domain('/work/username/perlbrew-libs');

Users often generate a large number of libraries which can quickly result in a
long list generated in the output of L</"perlbrew_list">. This experimental
feature allows for switching between I<domains> to reduce the size of these
lists. Thus, a collection of libraries are organised under domains. These are
only directories, must exist before use and are synonymous with
C<$ENV{PERLBREW_HOME}>. Indeed, this is a convenient alternative to
C<$App::perlbrew::PERLBREW_HOME>.

=head2 perlbrew_lib_create

  # 1 - success
  IPerl->perlbrew_lib_create('reproducible');
  # 0 - already exists
  IPerl->perlbrew_lib_create('reproducible');
  # -1 - no library name given
  IPerl->perlbrew_lib_create();

This is identical to C<<< perlbrew lib create >>>. Returns C<1>, C<0> or C<-1>
for I<success>, I<already exists> and I<error> respectively.

=head2 perlbrew_list

  IPerl->perlbrew_list;

This is identical to C<<< perlbrew list >>> and will output the same information.

=head2 perlbrew_list_modules

  IPerl->perlbrew_list_modules;

This is identical to C<<< perlbrew list_modules >>> and will output the same
information.

=head1 ENVIRONMENT VARIABLES

The following environment variables alter the behaviour of the plugin.

=over 4

=item IPERL_PLUGIN_PERLBREW_DEBUG

A logical to control how verbose the plugin is during its activities.

=item IPERL_PLUGIN_PERLBREW_CLASS

This defaults to L<App::prelbrew>

=back

=head1 INTERNAL INTERFACES

These are part of the internal interface and not designed for end user
consumption.

=head2 brew

  $plugin->brew;

Use the perlbrew library specified in L</"name">.

=head2 env

  $plugin->env({PERLBREW_ROOT => '/sw/perlbrew', ...});
  # {PERLBREW_ROOT => '/sw/perlbrew', ...}
  $plugin->env;

An accessor that stores the environment from L<App::perlbrew> for a subsequent
call to L</"brew">.

=head2 new

  my $plugin = Devel::IPerl::Plugin::Perlbrew->new();

Instantiate an object.

=head2 name

  $plugin->name('perl-5.26.0@reproducible');
  # perl-5.26.0@reproducible
  $plugin->name;

An accessor for the name of the perlbrew library.

=head2 saved

  $plugin->saved;

An accessor for the previous environment variables so they may be restored as
the L</"brew"> L</"spoil">s.

=head2 spoil

  $plugin->spoil;

When a L</"brew"> is finished with. This is called automatically during object
destruction.

=head2 success

  # boolean where 1 == success, 0 == not success
  $plugin->success;

Was everything a success?

=head2 unload

  $plugin->unload(1);
  # 1
  $plugin->unload;

A flag to determine whether to unload all the modules that were used as part of
this library during cleanup.

=cut
