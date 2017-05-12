
use Test::More tests => 12;

BEGIN {use_ok('Tree::Numbered') };
BEGIN {use_ok('HTML::Widget::SideBar') };

my $max_level = 3;

my $tree = Tree::Numbered->new('Root');
my $child = $tree->append(value => "First");
$tree->append(value => "Second");
$child->append(value => "First child");

HTML::Widget::SideBar->convert(tree => $tree);
isa_ok ($tree, "HTML::Widget::SideBar", "convert");

ok   ($child = $tree->append("Something", '0'), "appending");
is   ($child->getAction, $tree->getAction, "assigning default action");
isnt ($child->getUniqueId, $tree->getUniqueId, "UniqueId is different");

my @lines = $tree->getHTML;
# is ($#lines, $max_level*3 + $tree->listChildNumbers - $tree->childCount, "all HTML produced");

# Testing the new separation between HTML and script
# and the needed 'changed' flag.

ok (! $tree->getChanged, "Starts as not changed");

# Do we get different scripts?
my $script = $tree->getScript;
$tree->setActive;
ok   ($tree->getChanged, "Changed");

# We set the active flag on the deepest node. 
# Easier with deepProcess().
$tree->deepProcess(sub { $_[0]->setActive } );
isnt ($script, $tree->getScript, "different script");

my $first = $tree->getHTML; # Holds an arrayref.
is (ref $first, 'ARRAY', "backwards compat.");
ok (! $tree->getChanged, "Resets to not changed after getHTML");

$tree->append(value => 'Third');
is (join(''. $tree->getHTML), join('', @$second), 
	"appending sets the changed flag");


