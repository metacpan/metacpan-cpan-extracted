#!perl

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers (
 threads => [ 'Lexical::Types' => 'Lexical::Types::LT_THREADSAFE()' ],
 'run_perl',
);

use Test::Leaner tests => 2;

SKIP: {
 my $status = run_perl <<' RUN';
  { package IntX; package IntY; package IntZ; }
  my ($code, @expected);
  sub cb {
   my $e = shift(@expected) || q{DUMMY};
   --$code if $_[0] eq $e;
   ()
  }
  use threads;
  $code = threads->create(sub {
   $code = @expected = qw<IntX>;
   eval q{use Lexical::Types as => \&cb; my IntX $x;}; die if $@;
   return $code;
  })->join;
  $code += @expected = qw<IntZ>;
  eval q{my IntY $y;}; die if $@;
  eval q{use Lexical::Types as => \&cb; my IntZ $z;}; die if $@;
  $code += 256 if $code < 0;
  exit $code;
 RUN
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0, 'loading the pragma in a thread and using it outside doesn\'t segfault';
}

SKIP: {
 my $status = run_perl <<' RUN';
  use threads;
  BEGIN { require Lexical::Types; }
  sub X::DESTROY {
   my $res = eval 'use Lexical::Types; sub Z::TYPEDSCALAR { 123 } my Z $z';
   exit 1 if $@;
   exit 2 if not defined $res or $res != 123;
  }
  threads->create(sub {
   my $x = bless { }, 'X';
   $x->{self} = $x;
   return;
  })->join;
  exit 0;
 RUN
 skip RUN_PERL_FAILED() => 1 unless defined $status;
 is $status, 0, 'Lexical::Types can be loaded in eval STRING during global destruction at the end of a thread';
}
