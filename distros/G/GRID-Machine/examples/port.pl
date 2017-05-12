#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

# test the format "machine:port"
my $host = 'casiano@orion:22';

my $machine = GRID::Machine->new(host => $host, uses => [ 'Sys::Hostname' ]);

my $r = $machine->sub( 
  rmap => q{
    my $f = shift; # function to apply
    die "Code reference expected\n" unless UNIVERSAL::isa($f, 'CODE');
      

    print "Inside rmap!\n"; # last message
    my @result;
    for (@_) {
      die "Array reference expected\n" unless UNIVERSAL::isa($_, 'ARRAY');

      gprint hostname(),": Processing @$_\n";

      
      push @result, [ map { $f->($_) } @$_ ];
    }

    gprintf "%12s:\n",hostname();
    for (@result) { 
      my $format = "%5d"x(@$_)."\n";
      gprintf $format, @$_ 
    }
    return @result;
  },
);
die $r->errmsg unless $r->ok;

my $cube = sub { $_[0]**3 };
$r = $machine->rmap($cube, [1..3], [4..6], [7..9]);
print $r;


