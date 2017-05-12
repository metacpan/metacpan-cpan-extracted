#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $host = shift || 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new(host => $host, uses => [ 'Sys::Hostname' ]);

my $r = $machine->sub( 
  rmap => q{
    my $f = shift; # function to apply
    die "Code reference expected\n" unless UNIVERSAL::isa($f, 'CODE');

    my @result;
    for (@_) {
      die "Array reference expected\n" unless UNIVERSAL::isa($_, 'ARRAY');
      
      print hostname().": processing row [ @$_ ]\n";
      push @result, [ map { $f->($_) } @$_ ];
    }
    return @result;
  },
);
die $r->errmsg unless $r->ok;

my $cube = sub { $_[0]**3 };
$r = $machine->rmap($cube, [1..3], [4..6], [7..9]);
print $r;

for ($r->Results) { 
  my $format = "%5d"x(@$_)."\n";
  printf $format, @$_ 
}

