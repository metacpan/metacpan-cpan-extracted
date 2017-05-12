#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $host = $ENV{GRID_REMOTE_MACHINE};
my $debug = shift() ? 1234 : 0; 

my $machine = GRID::Machine->new(
        host => $host, 
        debug => $debug,
        report => '/tmp/reportfile',
        cleanup => 0,
);

my $remote_uname = $machine->uname->results;
print "**************@$remote_uname**************\n";

$machine->sub( 
  rmap => q{
    my $f = shift; # function to apply
    die "Code reference expected\n" unless UNIVERSAL::isa($f, 'CODE');

    my @result;

    my $workdir = SERVER->{tmpdir};

    gprint "tmpdir = $workdir\n";
    SERVER->remotelog("files in '$workdir' = ".qx{ls -ltr $workdir});

    for (@_) {
      die "Array reference expected\n" unless UNIVERSAL::isa($_, 'ARRAY');
      push @result, [ map { $f->($_) } @$_ ];
    }
    return @result;
  },
);

my $cube = sub { $_[0]**3 };
my $r = $machine->rmap($cube, [1..3], [4..6], [7..9]);
die $r->stderr unless $r->ok;

for ($r->Results) { 
  my $format = "%5d"x(@$_)."\n";
  printf $format, @$_ 
}

