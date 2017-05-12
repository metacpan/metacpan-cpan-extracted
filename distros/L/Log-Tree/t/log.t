#!perl -w

use strict;
use warnings;

use File::Temp;
use File::Blarf;
use Log::Tree;

use Test::More tests => 16;

my $tempdir = File::Temp::tempdir( CLEANUP => 1 );
my $logfile = $tempdir.'/tests.log';
my $args = {
  'facility'  => 'log-tests',
  'filename'  => $logfile,
  'prefix'    => '',
};
my $Log = Log::Tree->new($args);

foreach my $sev (@{$Log->severities()}) {
  $Log->log( message => 'Hello World', level => $sev, );
  my @content = File::Blarf::slurp($logfile);
  ok(grep( {/$sev/i} @content));
  ok(grep( {/Hello World/} @content));
}

