#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

=encoding utf8

=head1 NAME

bad_plist.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/bad_plist.t

	# run a single test
	% prove t/bad_plist.t

=head1 AUTHORS

Original author: brian d foy C<< <bdfoy@cpan.org> >>

Contributors:

=over 4

=item Andy Lester C<< <andy@petdance.com> >>

=back

=head1 SOURCE

This file was originally in https://github.com/briandfoy/mac-propertylist

=head1 COPYRIGHT

Copyright © 2002-2022, brian d foy, C<< <bdfoy@cpan.org> >>

=head1 LICENSE

This file is licenses under the Artistic License 2.0. You should have
received a copy of this license with this distribution.

=cut

my $class = 'Mac::PropertyList';
my @import = qw( parse_plist parse_plist_file );

use_ok( $class, @import ) or BAIL_OUT( "$class did not compile\n" );

foreach my $string ( ( '', 'blirt', '<XML' ) ) {
	my $plist = eval { parse_plist( $string ) };
	my $at = $@;
	ok( length $at, '$@ has an error message' );
	like( $at, qr/doesn't look like a valid plist/,
		'$@ has the right error message' );
	}

foreach my $file ( ( 'Makefile.PL', 'MANIFEST' ) ) {
	my $plist = eval { parse_plist_file( $file ) };
	my $at = $@;
	ok( length $at, '$@ has an error message' );
	like( $at, qr/doesn't look like a valid plist/,
		'$@ has the right error message' );
	}

foreach my $file ( 'not_there' ) {
	my $plist = eval { parse_plist_file( $file ) };
	my $at = $@;
	ok( ! -e $file, "file [$file] is not there" );
	ok( length $at, '$@ has an error message' );
	like( $at, qr/does not exist/,
		'$@ has the right error message' );
	}

done_testing();
