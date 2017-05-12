#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(qc);

my $host = $ENV{GRID_REMOTE_MACHINE};
my $machine = GRID::Machine->new(host => $host, uses => [ 'Sys::Hostname' ]);

my $r = $machine->sub( iguales => qc q{
    my ($first, $sec) = @_;

    print hostname().": $first and $sec are ";

    if ($first == $sec) {
      print "the same\n";
      return 1;
    }
    print "Different\n";
    return 0;
  },
);
$r->ok or die $r->errmsg;

my $w = [ 1..3 ];
my $z = $w;
$r = $machine->iguales($w, $z);
print $r;
