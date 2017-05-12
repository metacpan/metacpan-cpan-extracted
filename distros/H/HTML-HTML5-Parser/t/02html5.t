## skip Test::Tabs
use Test::More tests => 3;
use HTML::HTML5::Parser;

my $parser = HTML::HTML5::Parser->new;

my $html = <<HTML;
<!doctype html public "+//IDN demiblog.org//Foo Bar//EN">
<title>foo</title>
<p x="quux">Foo
<ul xmlns:foo="http://example.com/"><li><b><i>Bar</b>t&lt;</i>
The inequality is 2<3 .<br>
<!--Hello-World --!></ul>
<body a="b"><p>Baz<p///></br>
<table>
<caption>CCC</CAPTION>
<p>HHH</p>
<tr><td>
</table>
HTML

ok(my $dom = $parser->parse_string($html), "parse_string works");
is($parser->dtd_public_id($dom), "+//IDN demiblog.org//Foo Bar//EN", "dtd_public_id works");

my @italics = $dom->getElementsByTagName('i');
my $lone_letter = $italics[1];
is($lone_letter->textContent, 't<', "parsing seems to follow HTML5 rules");

=head1 PURPOSE

Test basic functionality.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
