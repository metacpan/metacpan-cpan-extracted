#!perl

use strict;
use Benchmark qw/:all :hireswallclock/;
use Data::Dumper;

sub one {
  my $d=MMapDB->new(filename=>"tmpdb");
  $d->start;

  $d->begin;
  $d->clear;
  $d->commit;

  $d->begin;
  for( my $i=0; $i<2000; $i++ ) {
    my @k;
    push @k, pack("C*", map {65+int rand 6} 1..2) for (1..2);
    $d->insert([\@k, $i, $i]);
  }
  $d->commit;
  $d->stop;
}

sub tm {
  if( my $pid=open my $fh, "-|" ) {
    local $/;
    my $s=readline $fh;
    $s=~s/\A(.+\n)//;
    print $1;
    my $VAR1;
    return @{eval $s};
  } else {
    require MMapDB;
    my $title='v'.MMapDB->VERSION;
    print Dumper [$title, timethis -20, \&one, $title];
    exit 0;
  }
}
my %res=tm;
unshift @INC, "blib/lib", "blib/arch";
my %res=(%res, tm);
cmpthese \%res
