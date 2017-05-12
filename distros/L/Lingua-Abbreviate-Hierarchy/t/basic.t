#!perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Differences;
use Data::Dumper;
use Lingua::Ab::H;

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

sub newlah {
  ok my $lah = Lingua::Ab::H->new( @_, ns => \@ns ), 'new';
  isa_ok $lah, 'Lingua::Abbreviate::Hierarchy';
  return $lah;
}

{
  my $lah = newlah();
  eq_or_diff [ $lah->ab( @ns ) ], [
    qw(
     c.l.pe.mi
     c.l.pe.a
     c.l.pe.mo
     c.l.f
     c.l.ba
     c.l.ba.b
     c.l.bc
     c.l.py
     c.l.py.m
     c.l.co
     c.l.c
     )
   ],
   'abbr - no limits';
}

{
  my $lah = newlah( only => 2 );
  eq_or_diff [ $lah->ab( @ns ) ], [
    qw(
     c.l.perl.misc
     c.l.perl.advocacy
     c.l.perl.mod_perl
     c.l.forth
     c.l.basic
     c.l.basic.bbc
     c.l.bcpl
     c.l.python
     c.l.python.misc
     c.l.cobol
     c.l.c
     )
   ],
   'abbr - only 2';
}

{
  my $lah = newlah( keep => 2 );
  eq_or_diff [ $lah->ab( @ns ) ], [
    qw(
     c.l.perl.misc
     c.l.perl.advocacy
     c.l.perl.mod_perl
     c.lang.forth
     c.lang.basic
     c.l.basic.bbc
     c.lang.bcpl
     c.lang.python
     c.l.python.misc
     c.lang.cobol
     c.lang.c
     )
   ],
   'abbr - keep 2';
}

{
  my $lah = newlah( max => 9 );
  eq_or_diff [ $lah->ab( @ns ) ], [
    qw(
     c.l.pe.mi
     c.l.pe.a
     c.l.pe.mo
     c.l.forth
     c.l.basic
     c.l.ba.b
     c.l.bcpl
     c.l.py
     c.l.py.m
     c.l.cobol
     c.lang.c
     )
   ],
   'abbr - max 9';
}

{
  my $lah = newlah( max => 8, trunc => '*' );
  eq_or_diff [ $lah->ab( @ns ) ], [
    qw(
     *l.pe.mi
     c.l.pe.a
     *l.pe.mo
     c.l.f
     c.l.ba
     c.l.ba.b
     c.l.bcpl
     c.l.py
     c.l.py.m
     c.l.co
     c.lang.c
     )
   ],
   'abbr - max 8, trunc *';
}

{
  my @dom = qw(
   altavista.co.uk
   amazon.co.uk
   goodies.co.uk
   google.co.uk
   hexten.co.uk
   tagish.co.uk
  );
  my $lah = Lingua::Ab::H->new( ns => \@dom, flip => 1 );
  eq_or_diff [ $lah->ab( @dom ) ], [
    qw(
     al.c.u
     am.c.u
     good.c.u
     goog.c.u
     h.c.u
     t.c.u
     )
   ],
   'abbr - flip';
}

# vim:ts=2:sw=2:et:ft=perl

