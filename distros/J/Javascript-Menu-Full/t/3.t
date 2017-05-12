
use Test::More tests => 9;

BEGIN {use_ok('Tree::Numbered') };
BEGIN {use_ok('Javascript::Menu') };

my $max_level = 0;

my $tree = Tree::Numbered->new('Root');
my $child = $tree->append("First");
$tree->append("Second");
$child->append("First child");

 my $action = sub {
    my $self = shift;
    my ($level, $unique) = @_;
    
    if ($level > $max_level) {$max_level = $level}
    my $value = $self->getValue;
    return "caption_${unique}.innerHTML='$value'";
  };

Javascript::Menu->convert(tree => $tree, action => $action, legacy_encoding => 1);
isa_ok($tree, "Javascript::Menu", "convert");

ok($child = $tree->append("Something", '0'), "appending");
is ($child->getAction, $tree->getAction, "assigning default action");
isnt($child->getUniqueId, $tree->getUniqueId, "UniqueId is different");

my @lines = $tree->getHTML;
is ($#lines, $max_level + 1, "all HTML produced");

@lines = grep /<a .*>/, @lines;
is ($#lines, $max_level + 1, "IE6 compatible code.");

@lines = grep /<a .*>/, $tree->getHTML(no_ie => 'i wish');
is ($#lines, -1, "IE6 incompatible code.");
