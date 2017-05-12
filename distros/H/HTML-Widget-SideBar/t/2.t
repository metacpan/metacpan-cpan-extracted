
use Test::More tests => 19;
BEGIN { use_ok('Tree::Numbered') };

my $tree = Tree::Numbered->new(Place => 'Root', Status => 'superman');
ok ($tree, "constructor");
ok (!$tree->hasField('Value'), "Value not created");

my $child = $tree->append(Place => "First", Status => 'ok');
ok ($child, "append");
is ($tree, $child->getParentRef, "parent assignment");

my @fields = $child->getFieldNames;
my @want_fields = ('Place', 'Status');
ok (eq_set(\@fields, \@want_fields), "Fields ok");
ok ($child->getField('Place') eq 'First', "getField works");
$child->setField('Place', '#1');
ok ($child->getField('Place') eq '#1', "setField works");

my $secChild;
ok ($secChild = $tree->append(), "no fields");
ok ($secChild->getField('Place') eq 'Root', "field inheritance");
ok (!$tree->hasField('Value'), "Value not created when no params");

ok ($secChild = $child->append("First child"), "deep append");
ok ($secChild->hasField('Value'), "Value auto-created");

my $cloned = $tree->clone;
isa_ok($cloned, "Tree::Numbered", "cloning");
isn't ($tree, $cloned->nextNode->getParentRef, "parent assignment in cloning 1");
is ($cloned, $cloned->nextNode->getParentRef, "parent assignment in cloning 2");

@ch1 = sort $cloned->listChildNumbers;
@ch2 = sort $tree->listChildNumbers;
ok(eq_set(\@ch1, \@ch2), "cloning and descendants");
isnt ($cloned->getLuckyNumber, $tree->getLuckyNumber, "lucky numbers are different");

$tree->addField('Special', 'not special');
ok ($tree->getSpecial eq 'not special', "Autoloading and adding fields");

# For more info:
# use Data::Dumper;
# print Dumper($tree);
