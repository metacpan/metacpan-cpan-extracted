#!/usr/bin/perl -w

use Test::More tests => 140;
use Test::NoWarnings;
use Mac::Finder::DSStore qw( getDSDBEntries putDSDBEntries );
use Mac::Finder::DSStore::BuddyAllocator;
use IO::File;
use File::Temp qw( tempfile );

#
# This is similar to recs_rw.t, but tests the btree code rather than the
# record packing/unpacking code.
#
# The $testpoint hook is used to do some extra consistency/roundtrip
# tests.
#

sub test_more_hook {
    my($l, $r) = @_;
    my(undef, $file, $line) = caller;
    $file =~ s/^.*\///;
    is_deeply($_[0], $_[1], "testpoint at $file:$line");
}
$Mac::Finder::DSStore::testpoint = \&test_more_hook;


(undef, $filename) = tempfile();
print "# temporary file is $filename\n";

{
    my($fh) = new IO::File $filename, '+>';
    $store = Mac::Finder::DSStore::BuddyAllocator->new($fh);
}

{
    my(@r);
    push(@r, &bigrec("Number $_")) foreach 1 .. 10;
    &put_and_get('Ten records, no internal nodes', 0, @r);
}

{
    my(@r);
    push(@r, &bigrec("Number $_")) foreach 1 .. 100;
    &put_and_get('One hundred records, one internal node', 1, @r);
}

{
    my(@r);
    push(@r, &bigrec("Number $_")) foreach 1 .. 500;
    &put_and_get('Five hundred records, two levels of internal nodes', 2, @r);
}

{
    my(@r);
    push(@r, &bigrec("Number $_")) foreach 1 .. 5;
    &put_and_get('Five records, no internal nodes', 0, @r);
}

# At this point, the store should be back to only 3 allocated
# blocks (the allocator's block, the btree root block, and the
# solitary btree node)
is(scalar(grep { defined $_ } @{$store->{offsets}}), 3, "allocated node count");

$store->close;
unlink($filename);

sub bigrec {
    my($fn) = $_[0];
    my($r) = Mac::Finder::DSStore::Entry->new($fn, 'cmmt');
    $r->value('For filename ['.$fn.'], this is a piece of text.'.
              ( ' This is yet more text.' x 5 ));
    $r;
}

sub put_and_get {
    my($explain) = shift;
    my($expect_height) = shift;
    my(@recs) = sort { $a->cmp($b) } @_;

    putDSDBEntries($store, \@recs);
    ok($store->listBlocks, 'Write store consistency');
    $store->writeMetaData;

    my($readback) = Mac::Finder::DSStore::BuddyAllocator->open(new IO::File $filename, '<');
    ok($readback->listBlocks, 'Readback store consistency');

    my($rootnode, $height, $nrec, $nnodes, $blksize) = $readback->blockByNumber($readback->{toc}->{DSDB})->read(20, 'N5');
    print "# rootnode: $rootnode  height: $height  nrec: $nrec  nnodes: $nnodes\n";
    is($nrec, scalar(@recs), "Record count ($explain)");
    is($height, $expect_height, "Tree height ($explain)");

    is_deeply( [ getDSDBEntries($readback) ], \@recs, "Record readback ($explain)" );
}

