#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $dist = shift or die "Usage:\n$0 distribution.tar.gz machine1 machine2 ... \n";

die "No distribution $dist found\n" unless -r $dist;
die "Distribution does not follow standard name convention\n" unless $dist =~ m{([\w.-]+)\.tar\.gz$};
my $dir = $1;

die "Usage:\n$0 distribution.tar.gz machine1 machine2 ... \n" unless @ARGV;
for my $host (@ARGV) {
  my $m = GRID::Machine->new( 
    host => $host,
    startdir => '/tmp',
  );
  my $r;

  #### transfer distribution.tar.gz
  $m->put([$dist]);

  #### untar
  $m->tar($dist, '-xz')->ok or do {
    warn "$host: Can't extract files from $dist\n";
    next;
  };

  #### cd distribution dir
  $m->chdir($dir)->ok or do {
    warn "$host: Can't change to directory $dir\n";
    next;
  };

  $GRID::Machine::stdoutbanner = "\n******$host STDOUT******\n";
  $GRID::Machine::stderrbanner = "\n******$host STDERR******\n";
  #### perl Makefile.PL
  next unless $m-> run('perl Makefile.PL');

  #### make
  next unless $m->run('make');

  ### make test
  next unless $m-> run('make test');
}
