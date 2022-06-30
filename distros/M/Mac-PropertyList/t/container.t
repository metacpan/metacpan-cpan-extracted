#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

container.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/container.t

	# run a single test
	% prove t/container.t

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

my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

foreach my $type ( qw(dict array) ) {
	my $type_class = $class . '::'. $type;
	my $dict = $type_class->new;
	isa_ok( $dict, $type_class );
	}

done_testing();
