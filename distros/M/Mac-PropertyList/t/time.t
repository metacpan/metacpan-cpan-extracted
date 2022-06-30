#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

time.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/time.t

	# run a single test
	% prove t/time.t

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

use Time::HiRes qw(tv_interval gettimeofday);

my $data = do {
	local @ARGV = qw(plists/com.apple.iTunes.plist);
	do { local $/; <> };
	};

my $time1 = [ gettimeofday ];
my $plist = Mac::PropertyList::parse_plist( $data );
my $time2 = [ gettimeofday ];

my $elapsed = tv_interval( $time1, $time2 );
note( "Elapsed time is $elapsed" );

ok($elapsed < 3, "Parsing time test");

done_testing();
