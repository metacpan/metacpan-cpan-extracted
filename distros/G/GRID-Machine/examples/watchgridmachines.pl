#!/usr/bin/perl -w
use strict;
use Data::Dumper;

use GRID::Machine;
my @MACHINE_NAMES = split /\s+/, $ENV{MACHINES};
my @m = map { GRID::Machine->new(host => $_) } @MACHINE_NAMES;

print $_->logic_id."\n" for (@m);

my @sub =  map { qq{sleep $_ ; SERVER->host().":$_" } } 1..@MACHINE_NAMES; 

{
my $i = 0;
$_->sub('do_something', $sub[$i++])  for @m;
}

my @p = map { $_->async('do_something') } @m;

my @r = do {
  my $i = 0;
  map { $_->waitpid($p[$i++]) } @m;
};

print Dumper(\@r);
