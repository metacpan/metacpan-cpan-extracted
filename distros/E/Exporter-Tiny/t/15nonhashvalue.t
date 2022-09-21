=pod

=encoding utf-8

=head1 PURPOSE

Test that C<< $value >> can be a non-hashref.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
	package Local::XYZ;
	use Exporter::Shiny 'mytest';
	sub _generate_mytest {
		my ( $class, $name, $value ) = @_;
		return sub { $value };
	}
};

{
	package Local::ABC1;
	use Local::XYZ mytest => [ 1, 2, 4 ];
	::is_deeply(
		mytest(),
		[ 1, 2, 4 ],
		'ARRAY ref',
	) or ::diag( ::explain( mytest() ) );
}

{
	package Local::ABC2;
	use Local::XYZ mytest => \123;
	::is_deeply(
		mytest(),
		\123,
		'SCALAR ref',
	) or ::diag( ::explain( mytest() ) );
}

{
	package Local::ABC3;
	use Local::XYZ mytest => qr/abc/;
	::is_deeply(
		mytest(),
		qr/abc/,
		'Regexp ref',
	) or ::diag( ::explain( mytest() ) );
}

