#!/usr/bin/perl -w

use Test::Simple tests => 61;
use Test::NoWarnings;

use Mac::Finder::DSStore::BuddyAllocator;
use Data::Dumper;  # For stringifying state

#
#  We cheat a little and don't even open a file, since
#  we're not going to commit any changes
#
$store = Mac::Finder::DSStore::BuddyAllocator->new( undef );

ok( $store->isa('Mac::Finder::DSStore::BuddyAllocator'), 'Allocator works' );
ok( $store->listBlocks(),  'Freelist is consistent' );

{
    my($dumper) = Data::Dumper->new([ $store ], [ 'allocator' ]);
    $dumper->Sortkeys(1);
    $dumper->Useqq(1);
    $emptystate = $dumper->Dump;
}

$count1 = 25;
%ids = ( );
$ids{$store->allocate(1)} = 1  foreach (1 .. $count1);
@ids = sort {$a<=>$b} keys %ids;
ok( $count1 == @ids, 'Block IDs are distinct');
ok( $ids[0] > 0,     'Block ID 0 is reserved');
print "# Last id is ".($ids[$#ids])."\n";
ok( $store->listBlocks(),  'Freelist is consistent' );

&checkSizes;

$d = eval {
    $store->blockOffset( 1 + $ids[$#ids] );
};
ok(!defined($d), 'Asking for the location of an unallocated block');
print "#    Return value was $d\n" if defined($d);

print "# Reallocating some of the blocks\n";
$bigger = 1024;
foreach my $ix (3, 6, 9, 2, 12, 20, 24, 8, 0)
{
    my($blkid) = $store->allocate($bigger, $ids[$ix]);
    ok( $blkid == $ids[$ix] );
    $ids{$blkid} = 1024;
    ok( $store->listBlocks() );
}

&checkSizes;

ok( 2 == $store->allocate($ids{2} = 200, 2) );
ok( 3 == $store->allocate($ids{3} = 255, 3) );
ok( 4 == $store->allocate($ids{4} = 256, 4) );
ok( 5 == $store->allocate($ids{5} = 257, 5) );

ok( $store->listBlocks() );
&checkSizes;

ok( 4 == $store->allocate($ids{4} = 255, 4) );

print "# Freeing a few of the blocks\n";
foreach my $ix (3, 7, 12, 15)
{
    my($blkid) = $ids[$ix];
    $store->free($blkid);
    delete $ids{$blkid};
    ok( $store->listBlocks() );
}

&checkSizes;

print "# Freeing the rest of the blocks\n";
foreach my $id (keys %ids)
{
    $store->free($id);
    ok( $store->listBlocks() );
}

{
    my($dumper) = Data::Dumper->new([ $store ], [ 'allocator' ]);
    $dumper->Sortkeys(1);
    $dumper->Useqq(1);
    $finalstate = $dumper->Dump;
}

ok( $emptystate eq $finalstate, 'Allocator has returned to initial state');

sub checkSizes {
    my(@fail);
    my($minalloc) = 32;

    foreach my $blkid (keys %ids) {
        my($s, @ss);

        $s = $store->blockOffset($blkid);
        @ss = $store->blockOffset($blkid);

        push(@fail, 'blockOffset inconsistent in array/scalar context')
            if 2 != @ss or $s != $ss[0];
        my($blksize) = $ss[1];
        push(@fail, "wrong block size id=$blkid sz=$blksize want=$ids{$blkid}")
            if $blksize < $ids{$blkid} or ($blksize > $minalloc and $ss[1] >= 2*$ids{$blkid});
    }

    ok(!@fail, join(' -- ', @fail));
}
