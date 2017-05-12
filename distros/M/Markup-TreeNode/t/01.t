use Test::Simple tests => 3;

use Markup::TreeNode;

ok(1);

my $node = Markup::TreeNode->new ( tagname => 'p', text => '-->test' );

ok($node);

ok(($node->{'tagname'} eq 'p') && ($node->{'text'} eq '-->test'));