use Test::Simple tests => 8;

use XML::Parser;

ok(1);

use HTML::TreeBuilder;

ok(1);

use Markup::TreeNode;

ok(1);

use File::Temp;

ok(1);

use LWP::Simple;

ok(1);

use Markup::Tree;

ok(1);

my $mt = Markup::Tree->new();

ok($mt);

ok($mt->parse_file('http://search.cpan.org'));