# 00-basic.t
#
# Test suite for Integer::Partition
# Make sure the basic stuff works
#
# copyright (C) 2007-2013 David Landgren

use strict;

use Test::More tests => 7;

use Integer::Partition;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

diag( "testing Integer::Partition v$Integer::Partition::VERSION" );

{
    my $t = Integer::Partition->new(1);
    ok( defined($t), 'new() defines ...' );
    ok( ref($t) eq 'Integer::Partition', '... a Integer::Partition object' );

    my $r = $t->next;
    is( ref($r), 'ARRAY', '... returns an arrayref' );

    $t = Integer::Partition->new(1, 2);
    ok( defined($t), 'new() ignores trailing parameter' );

    $t = Integer::Partition->new(1, [2]);
    ok( defined($t), 'new() ignores trailing ref' );

    $t = Integer::Partition->new(1, {bogus => 2});
    ok( defined($t), 'new() ignores unknown key' );
}

cmp_ok( $_, 'eq', $Unchanged, '$_ has not been altered' );
