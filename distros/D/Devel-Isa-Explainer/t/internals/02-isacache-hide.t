use strict;
use warnings;

use Test::More;

# ABSTRACT: Test for isa-cache overrides being detected

use Devel::Isa::Explainer ();

@ClassA::ISA = ('ClassB');
@ClassB::ISA = ('ClassC');

sub ClassC::fun { print q[hello] }
{
  no warnings 'once';
  *ClassA::fun = \&ClassC::fun;
}
*extract_mro = \&Devel::Isa::Explainer::_extract_mro;
$INC{ 'Class' . $_ . q[.pm] } = 1 for qw( A B C );

{
  my $mro = extract_mro('ClassA');
  my $oks = 3;
  my @errors;

  for my $class ( grep { $_->{class} eq 'ClassA' } @{$mro} ) {
    eval { $oks-- if ok( !scalar keys %{ $class->{subs} }, 'ClassA has no subs' ) } or push @errors, $@;
  }
  for my $class ( grep { $_->{class} eq 'ClassB' } @{$mro} ) {
    eval { $oks-- if ok( !scalar keys %{ $class->{subs} }, 'ClassB has no subs' ) } or push @errors, $@;
  }
  for my $class ( grep { $_->{class} eq 'ClassC' } @{$mro} ) {
    eval { $oks-- if ok( scalar keys %{ $class->{subs} }, 'ClassC has subs' ) } or push @errors, $@;
  }
  $oks == 0 or do {
    fail("Expected 0 residual tests, got $oks");
    diag explain $mro;
    diag explain \@errors;
  };
}
{
  # adding a function in the middle of a single functions inheritance
  # heirachy changes the view from shadow-perspective
  eval "sub ClassB::fun { print q[world] }";
  my $mro = extract_mro('ClassA');
  my $oks = 3;
  my @errors;

  for my $class ( grep { $_->{class} eq 'ClassA' } @{$mro} ) {
    eval { $oks-- if ok( scalar keys %{ $class->{subs} }, 'ClassA has subs post-mod' ) } or push @errors, $@;
  }
  for my $class ( grep { $_->{class} eq 'ClassB' } @{$mro} ) {
    eval { $oks-- if ok( scalar keys %{ $class->{subs} }, 'ClassB has subs post-mod' ) } or push @errors, $@;
  }
  for my $class ( grep { $_->{class} eq 'ClassC' } @{$mro} ) {
    eval { $oks-- if ok( scalar keys %{ $class->{subs} }, 'ClassC has subs post-mod' ) } or push @errors, $@;
  }
  $oks == 0 or do {
    fail("Expected 0 residual tests, got $oks");
    diag explain $mro;
    diag explain \@errors;
  };
}

done_testing;
