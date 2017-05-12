# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Jabber::Connection;
use Jabber::NodeFactory;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$cnt = 1;

# this nice function taken from WeakRef's test.pl. Thanks.
sub ok {
    ++$cnt;
    if($_[0]) { print "ok $cnt\n"; } else {print "not ok $cnt\n"; }
}

#
# Simple NodeFactory tests
#

my $nf = new Jabber::NodeFactory;

# newNode()
my $node = $nf->newNode('root');
ok ( ref($node) eq 'Jabber::NodeFactory::Node' );

# name()
ok ( $node->name eq 'root' );

# insertTag()
my $child1 = $node->insertTag('child1');
ok ( $child1->name eq 'child1' );

# getChildren()
my $child2 = $nf->newNode('child2');
$node->insertTag($child2);
ok ( join('-', map { $_->name } $node->getChildren) eq 'child1-child2');

# parent()
ok ( $child1->parent->name eq 'root' );
ok ( $child2->parent->name eq 'root' );

# attr()
$child1->attr('colour', 'red');
ok ( $child1->attr('colour') eq 'red' );

