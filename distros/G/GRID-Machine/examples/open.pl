#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new( 
      host => $host,
      startdir => '/tmp',
   );

my $r = $machine->sub( open => q{
    my $mode = shift;
    my $file;
    open($file, $mode) or die "Can't open $mode\n";
    return $file;
  }
);
die $r->errmsg unless $r->ok;

my $filename = shift;
my $text = shift;

my $file = $machine->open("> $filename");
$file->ok or die "Can't open $filename\n";
$file = $file->result;
$r = $machine->eval( q{
#line 30 "open.pl"
    my ($file, $text) = @_;

    print $file $text;
    close($file);
  },
  $file,
  $text
);
$r->ok or die $r->errmsg;
