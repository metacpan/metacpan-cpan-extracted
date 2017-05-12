#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use MMapDB qw/:error/;
use Encode qw/is_utf8/;

sub enc($);   *enc=\&Encode::encode_utf8;
sub dec($;$); *dec=\&Encode::decode_utf8;

sub note; *note=sub {
  print '# '.join('', @_)."\n";
} unless defined &note;

plan tests=>6;
#plan 'no_plan';
use Data::Dumper; $Data::Dumper::Useqq=1;

unlink 'tmpdb';			# make sure
unlink 'tmpdb.lock';		# make sure
die "Please move tmpdb out of the way!\n" if -e 'tmpdb';

my (@pos, @pos2, $got, $expected);

my $d=MMapDB->new(filename=>"tmpdb");

my @key=(qw/hokus pokus/);
my @keyu=map {dec $_} @key;
my @val=('ксенины груши', "Xenia's Birnen");
my @valu=map {dec $_} @val;

$d->start;
$d->begin();
my $sort="AAAA";
foreach my $v (@val) {
  $d->insert([\@key, $sort++, $v]);
}
foreach my $v (@valu) {
  $d->insert([\@keyu, $sort++, $v]);
}
$d->commit;
$d->stop;

$d->start;

####### Checking key1 ##############################################
note "Checking key (non utf8)";

@pos=$d->index_lookup($d->mainidx, @key);
is scalar @pos, 4, 'got 4 records';

####### Checking key1 ##############################################
note "Checking key (utf8)";

@pos2=$d->index_lookup($d->mainidx, @keyu);
is scalar @pos2, 4, 'got 4 records';
is_deeply \@pos2, \@pos, 'same positions';

$d->stop;

####### Now with reversed insert order #############################
note "Reversing insert order";

$d->start;
$d->begin();
$d->clear();
$sort="AAAA";
foreach my $v (@valu) {
  $d->insert([\@keyu, $sort++, $v]);
}
foreach my $v (@val) {
  $d->insert([\@key, $sort++, $v]);
}
$d->commit;
$d->stop;

$d->start;

####### Checking key1 ##############################################
note "Checking key (non utf8)";

@pos=$d->index_lookup($d->mainidx, @key);
is scalar @pos, 4, 'got 4 records';

####### Checking key1 ##############################################
note "Checking key (utf8)";

@pos2=$d->index_lookup($d->mainidx, @keyu);
is scalar @pos2, 4, 'got 4 records';
is_deeply \@pos2, \@pos, 'same positions';

$d->stop;
