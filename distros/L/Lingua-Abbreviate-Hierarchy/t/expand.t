#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Data::Dumper;
use Lingua::Ab::H;

my @case = (
  { name => 'clean',  args => [] },
  { name => 'keep 1', args => [ keep => 1 ] },
  { name => 'only 1', args => [ only => 1 ] },
  { name => 'flip',   args => [ flip => 1 ] },
  { name => 'max 9',  args => [ max => 9 ] },
);
plan tests => @case * 1;

for my $case ( @case ) {
  my $name = $case->{name};
  my $args = $case->{args};

  my @ns = qw(
   comp.lang.perl.misc
   comp.lang.perl.advocacy
   comp.lang.perl.mod_perl
   comp.lang.forth
   comp.lang.basic
   comp.lang.basic.bbc
   comp.lang.bcpl
   comp.lang.python
   comp.lang.python.misc
   comp.lang.cobol
   comp.lang.c
  );

  my $lah = Lingua::Ab::H->new( ns => \@ns, @$args );
  my @got = $lah->ab( @ns );
  my @ex  = $lah->ex( @got );
  eq_or_diff [@ex], [@ns], "$name: expand";
}

# vim:ts=2:sw=2:et:ft=perl

