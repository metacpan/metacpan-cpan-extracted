=head1 PURPOSE

Test handling of utf-8 encoded file data

=head1 SEE ALSO

=over 4

=item * L<https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=750946>

=item * L<https://rt.cpan.org/Public/Bug/Display.html?id=96399>

=back

=head1 AUTHOR

Gregory Todd Williams, E<lt>gwilliams@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2017 by Gregory Todd Williams

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Test::More tests => 2;
use Test::Requires 'LWP::UserAgent';
use HTML::HTML5::Parser;
use Encode qw(decode_utf8);

subtest 'U+2193 DOWNWARDS ARROW' => sub {
	my $filename  = 't/data/rt-96399-1.html';
	my $parser    = HTML::HTML5::Parser->new;
	my $doc       = $parser->parse_file($filename);
	is($parser->charset($doc), 'utf-8', 'recognized encoding as utf-8');
	like(decode_utf8($doc->toString()), qr/\x{2193}/, 'encoding properly round-trips U+2193 DOWNWARDS ARROW');
};

subtest 'U+00E9 LATIN SMALL LETTER E WITH ACUTE' => sub {
	my $filename  = 't/data/rt-96399-2.html';
	my $parser    = HTML::HTML5::Parser->new;
	my $doc       = $parser->parse_file($filename);
	is($parser->charset($doc), 'utf-8', 'recognized encoding as utf-8');
	like(decode_utf8($doc->toString()), qr/\x{00E9}/, 'encoding properly round-trips U+00E9 DOWNWARDS ARROW');
};
