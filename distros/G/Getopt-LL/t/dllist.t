use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use English qw( -no_match_vars );
use lib 'lib';
use lib 't';
use lib $Bin;
use lib "$Bin/../lib";

use TestDLListCompare;
use TestArrayOverload;

our $THIS_TEST_HAS_TESTS = 105;

plan( tests => $THIS_TEST_HAS_TESTS );

use Getopt::LL::DLList;

my @test_array = qw(
    The quick brown fox jumps over the lazy dog
);

my $dll = Getopt::LL::DLList->new(\@test_array);
my $cmp = TestDLListCompare->new(\@test_array);

ok(!$dll->delete_node(), 'delete_node without node');

###diag('Traverse and compare full list...');
$dll->traverse($cmp, 'compare');

my $head = $dll->head;
#diag('Delete element#3 and traverse+compare list.');

my $brown = $head->next->next;
is ($brown->data, 'brown');
$dll->delete_node($head->next->next);
my $check = $head->next->next;
ok ($check->data ne 'brown');

my @new  = (@test_array[0..1], @test_array[3..$#test_array]);
my $cmp2 = TestDLListCompare->new(\@new);

$dll->traverse($cmp2, 'compare');

#diag('Delete the head node and traverse+compare list.');
$dll->delete_node($head);
my @new2 = @new[1..$#new];
my $cmp3 = TestDLListCompare->new(\@new2);
$dll->traverse($cmp3, 'compare');

##diag('Delete the bottom node and traverse+compare list.');

my $bottom = $dll->head;
NODE:
while (1) {
    $bottom->next   ? $bottom = $bottom->next
                    : last NODE;
}
$dll->delete_node($bottom);

my $n = $#new2 - 1;
my @new3 = @new2[0..$n];
my $cmp4 = TestDLListCompare->new(\@new3);

$dll->traverse($cmp4, 'compare');

ok( Getopt::LL::DLList->new() , 'New DLList with no argument');
ok( Getopt::LL::DLList->new([]) , 'New DLList with emtpy array ref');

my $test_hash = do { eval 'Getopt::LL::DLList->new({ask => "hei"})' };
ok(!$test_hash, 'dont support hash refs');
like($EVAL_ERROR, qr/Argument to Getopt::LL::DLList must be array reference/);

ok(Getopt::LL::DLList::_ARRAYLIKE([]), '_ARRAYLIKE empty array reference');
ok(Getopt::LL::DLList::_ARRAYLIKE([1]),'_ARRAYLIKE populated array reference');
ok(Getopt::LL::DLList::_ARRAYLIKE(bless [], 'TestArray'),
    '_ARRAYLIKE blessed array'
);
ok(!Getopt::LL::DLList::_ARRAYLIKE( {} ), '!_ARRAYLIKE empty anon hash');
ok(!Getopt::LL::DLList::_ARRAYLIKE(1),    '!_ARRAYLIKE popul. anon hash');
ok(!Getopt::LL::DLList::_ARRAYLIKE(),    '!_ARRAYLIKE no arg');

my $ao = TestArrayOverload->new();
my $t = Getopt::LL::DLList::_ARRAYLIKE($ao) ? 1 : 0;
ok($t, '_ARRAYLIKE overloaded array deref');

$dll->DESTROY;
ok(!$dll->head, 'head gone after destroy');
