use Test::More;
use Markdown::Simple;

my $markdown = q|
# ƒøøøøøøøb
😀
|;

use Data::Dumper;
my $markdown = markdown_to_html($markdown);

is($markdown, '<div><h1>ƒøøøøøøøb</h1>😀</div>');

done_testing();
