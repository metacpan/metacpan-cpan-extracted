#!/usr/bin/perl -w

use File::Temp qw( tempfile );
use Test::NoWarnings;
use Test::More tests => 36;
use Mac::Finder::DSStore::BuddyAllocator;
use IO::File;

my($fh, $filename) = tempfile();
die "Couldn't open a temporary file" unless defined $fh;
print "# Working file is $filename\n";

$d = eval {
    Mac::Finder::DSStore::BuddyAllocator->open(new IO::File $filename, '<');
};
ok(!defined($d), "Shouldn't be able to open a 0-length file");

{
    my $store = Mac::Finder::DSStore::BuddyAllocator->new(new IO::File $filename, '>');
    $store->writeMetaData();
    ok($store->listBlocks(), 'Freelist is consistent');
    $store->close();
}

$fh = new IO::File $filename, '+<';
die "Couldn't reopen temporary file" unless defined $fh;
{
    my $store = Mac::Finder::DSStore::BuddyAllocator->open($fh);
    ok($store->listBlocks(), 'Freelist is consistent');
    my($a) = $store->{offsets};
    is(scalar(@$a), 1, 'Only allocated block is metadata block');
    is_deeply($store->{toc}, { }, 'TOC is empty');

    $store->{toc}->{FOO} = $store->allocate(327);
    $store->{toc}->{BAR} = $store->allocate(9099);
    $store->{toc}->{BAZ} = $store->allocate(327);
    is(scalar(@$a), 4, 'Should be four allocated blocks now');
    ok($store->listBlocks(), 'Freelist is consistent');
    $store->writeMetaData();

    &readback($store, $filename);

    # Make a gap in the block numbers
    $store->{toc}->{BONK} = $store->allocate(327);
    $store->free($store->{toc}->{BAZ});
    delete $store->{toc}->{BAZ};
    is(scalar(@$a), 5, 'Should be four allocated blocks and one gap now');
    ok($store->listBlocks(), 'Freelist is consistent');
    $store->writeMetaData();

    &readback($store, $filename);

    # Make sure this works near 256 allocated blocks
    $store->allocate(20) foreach (5 .. 255);
    is(scalar(@$a), 255, 'Should be 255 allocated blocks now');
    ok($store->listBlocks(), 'Freelist is consistent');
    $store->writeMetaData();
    &readback($store, $filename);

    $store->allocate(42);
    is(scalar(@$a), 256, 'Should be 256 allocated blocks now');
    ok($store->listBlocks(), 'Freelist is consistent');
    $store->writeMetaData();
    &readback($store, $filename);

    $store->allocate(29);
    is(scalar(@$a), 257, 'Should be 257 allocated blocks now');
    ok($store->listBlocks(), 'Freelist is consistent');
    $store->writeMetaData();
    &readback($store, $filename);


    $store->close();
}

unlink($filename);

sub readback {
    my($store1, $fn) = @_;
    my($pkg, $callfn, $callln) = caller;
    my($at) = "[&readback called from $callfn:$callln] ";
    my($store2) = Mac::Finder::DSStore::BuddyAllocator->open(new IO::File $filename, '<');
    ok($store2->listBlocks(), $at.'Freelist is consistent');
    is_deeply($store2->{freelists}, $store1->{freelists}, $at.'Freelist roundtrip');
    is_deeply($store2->{offsets}, $store1->{offsets}, $at.'Block offset roundtrip');
    is_deeply($store2->{toc}, $store1->{toc}, $at.'TOC roundtrip');
    $store2->close();
}

