#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
# This program produces an error

my $host = 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new(host => $host, uses => [ qw(POSIX) ]);

my $remote_uname = $machine->uname->results;
print "**************@$remote_uname**************\n";

my $r = $machine->sub( 
  rmap => q{
    my $f = shift; # function to apply
    die "Code reference expected\n" unless UNIVERSAL::isa($f, 'CODE');

    my @result;

    for (@_) {
      die "Array reference expected\n" unless UNIVERSAL::isa($_, 'ARRAY');
      push @result, [ map { $f->($_) } @$_ ];
    }
    return @result;
  },
);
die $r->errmsg unless $r->ok;

# $cube has to be a CODE ref. This is the error
my $cube = "error";
$r = $machine->rmap($cube, [1..3], [4..6], [7..9]);
die "$r" unless $r->ok;

for ($r->Results) { 
  my $format = "%5d"x(@$_)."\n";
  printf $format, @$_ 
}

