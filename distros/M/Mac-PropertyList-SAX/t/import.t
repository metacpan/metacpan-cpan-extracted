#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

import.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/import.t

	# run a single test
	% prove t/import.t

=head1 AUTHORS

Original author: brian d foy C<< <bdfoy@cpan.org> >>

=head1 SOURCE

This file was originally in https://github.com/briandfoy/mac-propertylist

=head1 COPYRIGHT

Copyright © 2002-2022, brian d foy, C<< <bdfoy@cpan.org> >>

=head1 LICENSE

This file is licenses under the Artistic License 2.0. You should have
received a copy of this license with this distribution.

=cut

my $class = 'Mac::PropertyList::SAX';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

ok( ! defined( &parse_plist ), "parse_plist is not defined yet" );
my $result = $class->import( 'parse_plist' );
ok( defined( &parse_plist ), "parse_plist is now defined" );

my @subs = @{ $class . '::EXPORT_OK' };
foreach my $name ( @subs ) {
	next if $name eq 'parse_plist';
	ok( ! defined( &$name ), "$name is not defined yet" );
	}

Mac::PropertyList::SAX->import( ":all" );

foreach my $name ( @subs ) {
	ok( defined( &$name ), "$name is now defined yet" );
	}

done_testing();
