## skip Test::Tabs
use Test::More tests => 3;
BEGIN { use_ok('HTML::HTML5::Parser') };

my $parser = new_ok 'HTML::HTML5::Parser';
can_ok $parser, qw/
	parse_file parse_html_file
	parse_fh parse_html_fh
	parse_string parse_html_string
	parse_balanced_chunk
	load_xml load_html
	error_handler errors
	compat_mode dtd_public_id dtd_system_id dtd_element
	source_line
	/;

=head1 PURPOSE

Test that L<HTML::HTML5::Parser> can be loaded and instantiated, and that
the object has the expected methods.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2010-2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
