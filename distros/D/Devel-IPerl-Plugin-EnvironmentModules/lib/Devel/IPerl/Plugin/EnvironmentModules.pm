package Devel::IPerl::Plugin::EnvironmentModules;

use strict;
use warnings;
use Capture::Tiny ();
use Array::Diff ();
use Env::Modulecmd ();
use constant MODULECMD => $ENV{'PERL_MODULECMD'} || 'modulecmd';

our $VERSION = '0.03';

sub avail {
  my @args = (MODULECMD, qw{perl avail});
  my ($stderr, @result) = Capture::Tiny::capture_stderr { system { $args[0] } @args };
  return $stderr;
}

sub load  {
  shift->_env_diff(sub { local ($^W) = 1; Env::Modulecmd::_modulecmd('load', @_); }, @_);
}

sub list  {
  my @args = (MODULECMD, qw{perl list});
  my ($stderr, @result) = Capture::Tiny::capture_stderr { system { $args[0] } @args };
  return $stderr;
}

sub list_array {
  my $self  = shift;
  my @lines = split m{\n}, $self->list || '';
  return [
    grep { length }
    map  { split m{(?:\s*\d+\)\s)} } @lines[1.. $#lines]
    ];
}

sub new   { bless {}, ref($_[0]) || $_[0]; }

sub register {
    my ($class, $iperl) = @_;
    my $self = $class->new;
    for my $name(qw{avail load unload list list_array search show}) {
      $iperl->helper("module_$name" => sub {
          my ($ip, $ret) = (shift, -1);
          return $ret if $name =~ /^(load|search|show|unload)$/ && @_ == 0;
          my $cb = $self->can($name);
          return $ret unless $cb;
          return $self->$cb(@_);
      });
    }
    return 1;
}

sub search {
  my ($self, $query) = @_;
  my $regex = ref($query) eq 'Regexp' ? $query : qr{\Q$query\E};
  my $hits  =
    join $/ => sort { lc($a) cmp lc($b) }
      grep { m/$regex/ } split m{(?:$/|\s+)}, $self->avail || '';
  return $hits || 'no match';
}

sub show {
  shift;
  my @args = (MODULECMD, qw{perl show}, @_);
  my ($stderr, @result) = Capture::Tiny::capture_stderr { system { $args[0] } @args };
  return $stderr;
}

sub unload {
  shift->_env_diff(sub { local ($^W) = 1; Env::Modulecmd::_modulecmd('unload', @_); }, @_);
}

## like around, but explicitly called.
sub _env_diff {
  my ($self, $orig) = (shift, shift);
  my %before = %ENV; # shallow copy

  my $ret = $orig->(@_);

  if (($before{PERL5LIB} || '') ne ($ENV{PERL5LIB} || '')) {
    my $old = [ split /:/, $before{PERL5LIB} || '' ];
    my $new = [ split /:/, $ENV{PERL5LIB}    || '' ];
    my $ad  = Array::Diff->new;
    $ad->diff($old, $new);
    ## add or remove with lib
    eval "use lib q[$_];" for (@{$ad->added});
    eval "no lib q[$_];" for (@{$ad->deleted});
  }

  return $ret;
}

1;

=pod

=head1 NAME

Devel::IPerl::Plugin::EnvironmentModules - Environment Modules

=begin html

<!-- Travis -->
<a href="https://travis-ci.org/kiwiroy/Devel-IPerl-Plugin-EnvironmentModules">
  <img src="https://travis-ci.org/kiwiroy/Devel-IPerl-Plugin-EnvironmentModules.svg?branch=master"
       alt="Build Status" />
</a>

<!-- Coveralls -->
<a href="https://coveralls.io/github/kiwiroy/Devel-IPerl-Plugin-EnvironmentModules?branch=master">
  <img src="https://coveralls.io/repos/github/kiwiroy/Devel-IPerl-Plugin-EnvironmentModules/badge.svg?branch=master"
       alt="Coverage Status" />
</a>

<!-- Kritika -->
<a href="https://kritika.io/users/kiwiroy/repos/6049167555239475/heads/master/">
  <img src="https://kritika.io/users/kiwiroy/repos/6049167555239475/heads/master/status.svg"
       alt="Kritika Analysis Status" />
</a>

=end html

=head1 DESCRIPTION

A plugin to use when you have L<environment modules|http://modules.sourceforge.net>
to work with.

The plugin is a wrapper for the L<Env::Modulecmd> perl module.

=head1 SYNOPSIS

  IPerl->load_plugin('EnvironmentModules') unless IPerl->can('module_load');
  IPerl->module_load('git');
  IPerl->module_unload('git');

=head1 INSTALLATION AND REQUISITES

=head1 IPerl Interface Method

=head2 register

Called by C<<< IPerl->load_plugin('EnvironmentModules') >>>.

=head1 REGISTERED METHODS

=head2 module_avail

  IPerl->module_list;

Display a list of environment modules that are available.

=head2 module_list

  IPerl->module_list;

Display the list of environment modules that are loaded.

=head2 module_list_array

  my $loaded = IPerl->module_list_array;

Return an array reference to the list of loaded modules as returned by
L</"module_list">.

=head2 module_load

  IPerl->module_load('gcc');

Load a list of environment modules.

=head2 module_search

  IPerl->module_search(qr/gcc/);
  IPerl->module_search('gcc');

Display a list of matching modules. The query can either be a regular expression
or a literal string.

=head2 module_show

  IPerl->module_show('gcc');

Display the environment modified by the given environment module.

=head2 module_unload

  IPerl->module_unload('gcc');

Unload a list of environment modules.

=head1 INTERNAL METHODS

Not for end user consumption.

=head2 avail

  my $p = Devel::IPerl::Plugin::EnvironmentModules->new();
  $p->avail;

A more longwinded C<<< IPerl->module_avail; >>>.

=head2 list

  my $p = Devel::IPerl::Plugin::EnvironmentModules->new();
  $p->list();

A more longwinded C<<< IPerl->module_list; >>>.

=head2 list_array

  my $p = Devel::IPerl::Plugin::EnvironmentModules->new();
  $p->list_array();

A more longwinded C<<< IPerl->module_list_array; >>>.

=head2 load

  my $p = Devel::IPerl::Plugin::EnvironmentModules->new();
  $p->load('gcc');

A more longwinded C<<< IPerl->module_load; >>>.

=head2 new

  my $p = Devel::IPerl::Plugin::EnvironmentModules->new();

Create a new instance.

=head2 search

  my $p = Devel::IPerl::Plugin::EnvironmentModules->new();
  $p->search(qr/gcc/);
  $p->search('gcc');

=head2 show

  my $p = Devel::IPerl::Plugin::EnvironmentModules->new();
  $p->show('gcc');

A more longwinded C<<< IPerl->module_show; >>>.

=head2 unload

  my $p = Devel::IPerl::Plugin::EnvironmentModules->new();
  $p->unload('gcc');

A more longwinded C<<< IPerl->module_unload; >>>.


=head1 SEE ALSO

=over 4

=item L<Env::Modulecmd>

=item L<Devel::IPerl>

=back

=cut
