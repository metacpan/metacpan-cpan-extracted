use Test::Simple tests => 7;

use Markup::Tree;

ok(1);

use Markup::TreeNode;

ok(1);

use Markup::MatchTree;

ok(1);

use Markup::Content;

ok(1);

my $content = Markup::Content->new( target => 'lib/Markup/noname.html',
				template => 'lib/Markup/noname.xml',
				target_options => {
					no_squash_whitespace => [qw(script style pi code pre textarea)]
				},
				template_options => {
					callbacks => {
						title => sub {
							print shift()->get_text();
						}
					}
				});

ok($content);

$content->extract();

ok($content->tree);

$content->tree->save_as(\*STDOUT, 'xml');

ok(1);