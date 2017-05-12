use strict;
use warnings;

use Test::More tests => 1;
use File::Temp qw(tempfile);
use MaxMind::DB::Reader;
use MaxMind::DB::Writer::FromTextFile qw(mmdb_create);

my ($fh, $tmp) = tempfile(UNLINK => 1);
mmdb_create("t/text/ip.txt", $tmp);

my $reader = MaxMind::DB::Reader->new( file => $tmp );
my $record = $reader->record_for_address('39.180.0.1');
is($record->{string}, "zhejiang|CM");



