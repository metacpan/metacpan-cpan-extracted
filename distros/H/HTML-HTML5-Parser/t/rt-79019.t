## skip Test::Tabs
use Test::More tests => 1;
use HTML::HTML5::Parser;

my $dom = HTML::HTML5::Parser::->load_html(IO => \*DATA);

is(
	$dom->documentElement->lookupNamespaceURI('fb'),
	'http://ogp.me/ns/fb#',
);

=head1 PURPOSE

Check that some weird namespace thing doesn't crash the parser.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=79019>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
<html>
<html xmlns:fb="http://ogp.me/ns/fb#">
</html>
