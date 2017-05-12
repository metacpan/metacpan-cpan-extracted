## skip Test::Tabs
use Test::More tests => 29;
use HTML::HTML5::Parser;

my $dom = HTML::HTML5::Parser->load_html(string => <<'HTML');
<!doctype html>
<html>
  <title>Test 5: Origins</title>
  <p>
    <b>This</b> <i>is</i>
    <a href="http://example.com/">a</a>
    <tt>test!</tt>
    <!--
        Hello
        World
    -->
</html>
HTML

can_ok 'HTML::HTML5::Parser' => 'source_line'
	or BAIL_OUT('No "source_line" method!!');

my @root = HTML::HTML5::Parser->source_line($dom->documentElement);
is($root[0], 2, 'root element has correct line number');
is($root[1], 1, 'root element has correct col number');
ok(!$root[2], 'root element explicit');

my @head = HTML::HTML5::Parser->source_line($dom->getElementsByTagName('head')->get_node(1));
ok(defined $head[0], 'head element has a line number');
ok(defined $head[1], 'head element has a col number');
ok($head[2], 'head element implicit');

my @title_text = HTML::HTML5::Parser->source_line($dom->getElementsByTagName('title')->get_node(1)->childNodes->get_node(1));
is($title_text[0], 3, 'text node in title element has a line number');
is($title_text[1], 10, 'text node in title element has a col number');
ok(!$title_text[2], 'text node in title element explicit');

my @para = HTML::HTML5::Parser->source_line($dom->getElementsByTagName('p')->get_node(1));
is($para[0], 4, 'p element has correct line number');
is($para[1], 3, 'p element has correct col number');
ok(!$para[2], 'para element explicit');

my $para = HTML::HTML5::Parser->source_line($dom->getElementsByTagName('p')->get_node(1));
is($para, 4, 'p element has correct line number (scalar context)');

my @b = HTML::HTML5::Parser->source_line($dom->getElementsByTagName('b')->get_node(1));
is($b[0], 5, 'b element has correct line number');
is($b[1], 5, 'b element has correct col number');
ok(!$b[2], 'b element explicit');

my @i = HTML::HTML5::Parser->source_line($dom->getElementsByTagName('i')->get_node(1));
is($i[0], 5, 'i element has correct line number');
is($i[1], 17, 'i element has correct col number');
ok(!$i[2], 'i element explicit');

my @a = HTML::HTML5::Parser->source_line($dom->getElementsByTagName('a')->get_node(1));
is($a[0], 6, 'a element has correct line number');
is($a[1], 5, 'a element has correct col number');
ok(!$a[2], 'a element explicit');

my @href = HTML::HTML5::Parser->source_line($dom->getElementsByTagName('a')->get_node(1)->getAttributeNode('href'));
is($href[0], 6, 'href attribute has correct line number');
is($href[1], 8, 'href attribute has correct col number');
ok(!$href[2], 'href attribute explicit');

# It's not easy to actually find comments in the DOM!
my $comment = $dom->getElementsByTagName('p')->[0]->childNodes->[-2];
my @comment = HTML::HTML5::Parser->source_line($comment);
is($comment[0], 8, 'comment has correct line number')
	or diag($comment->toString);
is($comment[1], 5, 'comment has correct col number');
ok(!$comment[2], 'comment is explicit');

=head1 PURPOSE

Check that line/column numbers are reported.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
