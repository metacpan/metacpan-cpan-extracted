#!/usr/bin/perl
use strict;
use warnings;
$|++;
 
use Time::HiRes qw( time );
use KinoSearch1::Store::FSInvIndex;
use KinoSearch1::Index::FieldInfos;
use KinoSearch1::Index::CompoundFileReader;
use KinoSearch1::Index::SegTermEnum;


my $invindex = KinoSearch1::Store::FSInvIndex->new(
    path => $ARGV[0],
);

my $cfs_reader = KinoSearch1::Index::CompoundFileReader->new(
    invindex => $invindex,
    seg_name => '_1',
);
my $finfos = KinoSearch1::Index::FieldInfos->new;
$finfos->read_infos( $cfs_reader->open_instream('_1.fnm'));

my $t0 = time;
while (1) {
    print ".";
#    1 for 1 .. 10000;
    my $instream = $cfs_reader->open_instream('_1.tis');
    my $enum = KinoSearch1::Index::SegTermEnum->new(
        finfos => $finfos,
        instream => $instream,
    );
    $enum->fill_cache();
   # 1 while defined (my $term = $enum->next);
}
print ((time - $t0) . " secs\n");
