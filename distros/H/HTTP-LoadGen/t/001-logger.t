#!perl

use strict;
use warnings;

use Test::More tests => 8;
#use Test::More 'no_plan';
use HTTP::LoadGen::Logger;

my @l=map {
  open my $f, '>', $_ or die "Cannot open $_: $!";
  HTTP::LoadGen::Logger::get $f;
} qw!log1 log2!;

isa_ok $l[0], 'CODE', '$l[0]';
isa_ok $l[1], 'CODE', '$l[1]';

for( my $i=0; $i<10; $i++ ) {
  $l[$i&1]->($i);
}

map {$_->()} @l;

{
  local $/;
  open my $f, 'log1' or die "Cannot open log1: $!";
  is scalar(readline $f), <<'EOF', 'log1 content';
0
2
4
6
8
EOF
}

{
  local $/;
  open my $f, 'log2' or die "Cannot open log2: $!";
  is scalar(readline $f), <<'EOF', 'log2 content';
1
3
5
7
9
EOF
}

@l=map {
  HTTP::LoadGen::Logger::get $_, sub {sprintf ":@_\n", @_};
} qw!log1 log2!;

isa_ok $l[0], 'CODE', '$l[0]';
isa_ok $l[1], 'CODE', '$l[1]';

for( my $i=0; $i<10; $i++ ) {
  $l[$i&1]->($i);
}

map {$_->()} @l;

{
  local $/;
  open my $f, 'log1' or die "Cannot open log1: $!";
  is scalar(readline $f), <<'EOF', 'log1 content';
0
2
4
6
8
:0
:2
:4
:6
:8
EOF
}

{
  local $/;
  open my $f, 'log2' or die "Cannot open log2: $!";
  is scalar(readline $f), <<'EOF', 'log2 content';
1
3
5
7
9
:1
:3
:5
:7
:9
EOF
}

unlink 'log1', 'log2';
