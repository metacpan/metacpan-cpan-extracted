## skip Test::Tabs
use Test::More;
use HTML::HTML5::Parser;

eval { require XML::LibXML::Devel::SetLineNumber; 1 }
	or plan skip_all => "Need XML::LibXML::Devel::SetLineNumber";

plan tests => 6;

my $dom = HTML::HTML5::Parser->load_html(string => <<'HTML');
<!doctype html>
<html>
  <title>Test 6: XML::LibXML::Devel::SetLineNumber</title>
  <p>
    <b>This</b> <i>is</i>
    <a href="http://example.com/">a</a>
    <tt>test!</tt>
</html>
HTML

is(
	$dom->documentElement->line_number,
	2,
	'root element has correct line number',
	);

ok(
	defined $dom->getElementsByTagName('head')->get_node(1)->line_number,
	'head element has a line number',
	);

is(
	$dom->getElementsByTagName('p')->get_node(1)->line_number,
	4,
	'p element has correct line number',
	);

is(
	$dom->getElementsByTagName('b')->get_node(1)->line_number,
	5,
	'b element has correct line number',
	);

is(
	$dom->getElementsByTagName('i')->get_node(1)->line_number,
	5,
	'i element has correct line number',
	);

is(
	$dom->getElementsByTagName('a')->get_node(1)->line_number,
	6,
	'a element has correct line number',
	);

=head1 PURPOSE

Check that L<XML::LibXML::Devel::SetLineNumber> can be used to get line
number information for XML elements.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
