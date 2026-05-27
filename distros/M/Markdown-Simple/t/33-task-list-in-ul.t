use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Task list items live inside a <ul> per GFM.
my $html = markdown_to_html("- [ ] unchecked task\n");
like $html, qr|<ul>|, 'task list wrapped in <ul>';
like $html, qr|<li>.*unchecked task.*</li>|s, '<li> emitted';

my $multi = markdown_to_html("- [ ] a\n- [x] b\n- [ ] c\n");
like   $multi, qr|<ul>.*a.*b.*c.*</ul>|s, 'consecutive task items in one <ul>';
unlike $multi, qr|</ul>\s*<ul>|,           'no spurious list breaks';

done_testing;
