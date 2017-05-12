package Devel::BeginLift;

use strict;
use warnings;
use 5.008001;

our $VERSION = 0.001003;

use vars qw(%lift);
use base qw(DynaLoader);
use B::Hooks::OP::Check::EntersubForCV;

bootstrap Devel::BeginLift;

sub import {
  my ($class, @args) = @_;
  my $target = caller;
  $class->setup_for($target => \@args);
}

sub unimport {
  my ($class) = @_;
  my $target = caller;
  $class->teardown_for($target);
}

sub setup_for {
  my ($class, $target, $args) = @_;
  $lift{$target} ||= [];
  push @{ $lift{$target} }, map {
    $class->setup_for_cv($_);
  } map {
    ref $_ eq 'CODE'
      ? $_
      : \&{ "${target}::${_}" }
  } @{ $args };
}

sub teardown_for {
  my ($class, $target) = @_;
  $class->teardown_for_cv($_) for @{ $lift{$target} };
  delete $lift{$target};
}

=head1 NAME

Devel::BeginLift - make selected sub calls evaluate at compile time

=head1 SYNOPSIS

  use Devel::BeginLift qw(foo baz);
  
  use vars qw($i);
  
  BEGIN { $i = 0 }
  
  sub foo { "foo: $_[0]\n"; }
  
  sub bar { "bar: $_[0]\n"; }
  
  for (1 .. 3) {
    print foo($i++);
    print bar($i++);
  }
  
  no Devel::BeginLift;
  
  print foo($i++);

outputs -

foo: 0
bar: 1
foo: 0
bar: 2
foo: 0
bar: 3
foo: 4

=head1 DESCRIPTION

Devel::BeginLift 'lifts' arbitrary sub calls to running at compile time
- sort of a souped up version of "use constant". It does this via some
slightly insane perlguts magic.

=head2 import

  use Devel::BeginLift qw(list of subs);

Calls Devel::BeginLift->setup_for(__PACKAGE__ => \@list_of_subs);

=head2 unimport

  no Devel::BeginLift;

Calls Devel::BeginLift->teardown_for(__PACKAGE__);

=head2 setup_for

  Devel::BeginLift->setup_for($package => \@subnames);

Installs begin lifting magic (unless already installed) and registers
"${package}::$name" for each member of @subnames to be executed when parsed
and replaced with its output rather than left for runtime.

=head2 teardown_for

  Devel::BeginLift->teardown_for($package);

Deregisters all subs currently registered for $package and uninstalls begin
lifting magic is number of teardown_for calls matches number of setup_for
calls.

=head2 setup_for_cv

  $id = Devel::BeginLift->setup_for_cv(\&code);

Same as C<setup_for>, but only registers begin lifting magic for one code
reference. Returns an id to be used in C<teardown_for_cv>.

=head2 teardown_for_cv

  Devel::BeginLift->teardown_for_cv($id);

Deregisters begin lifting magic referred to by C<$id>.

=head1 AUTHOR

Matt S Trout - <mst@shadowcatsystems.co.uk>

Company: http://www.shadowcatsystems.co.uk/
Blog: http://chainsawblues.vox.com/

=head1 LICENSE

This library is free software under the same terms as perl itself

=cut

1;
