#!perl -T

use strict;
use warnings;

use Config qw<%Config>;

use Test::More tests => 4;

sub Str::TYPEDSCALAR {
 my $buf = (caller(0))[2];
 open $_[1], '<', \$buf;
 ()
}

{
 use Lexical::Types;

 my Str $x;
 our $r = <$x>;
 is $r, __LINE__-2, 'trick for our - readline';

 my Str $y;
 my $s = <$y>;
 is $s, __LINE__-2, 'trick for my - readline';

 my $z = 7;
 is $z, 7, 'trick for others';
}

my @lines;

sub Int::TYPEDSCALAR { push @lines, (caller(0))[2]; () }

{
 use Lexical::Types as => sub {
  # In 5.10, this closure is compiled before hints are enabled, so no hintseval
  # op is added at compile time to propagate the hints inside the eval.
  # That's why we need to re-use Lexical::Types explicitely.
  eval 'use Lexical::Types; my Int $x';
  @_;
 };

 my Int $x;
 is_deeply \@lines, [ 1, __LINE__-1 ], 'hooking inside the \'as\' callback';
}
