use Test::Simple tests => 5;

use Markup::TreeNode;

ok(1);

use Markup::MatchNode;

ok(1);

my $node = Markup::MatchNode->new ( tagname => 'p', text => '-->test' );

ok($node);

ok(($node->{'tagname'} eq 'p') && ($node->{'text'} eq '-->test'));

ok($node->compare_to(Markup::TreeNode->new ( tagname => 'p', text => '-->test' )));