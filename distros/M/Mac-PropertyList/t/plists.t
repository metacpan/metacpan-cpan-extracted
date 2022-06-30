#!/usr/bin/env perl

BEGIN { @plists = glob( 'plists/*.plist' ); }

use Test::More;

=encoding utf8

=head1 NAME

plists.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/plists.t

	# run a single test
	% prove t/plists.t

=head1 AUTHORS

Original author: brian d foy C<< <bdfoy@cpan.org> >>

Contributors:

=over 4

=item Andy Lester C<< <andy@petdance.com> >>

=item Wim Lewis C<< <wiml@hhhh.org> >>

=item Tom Wyant C<< <wyant@cpan.org> >>

=back

=head1 SOURCE

This file was originally in https://github.com/briandfoy/mac-propertylist

=head1 COPYRIGHT

Copyright © 2002-2022, brian d foy, C<< <bdfoy@cpan.org> >>

=head1 LICENSE

This file is licenses under the Artistic License 2.0. You should have
received a copy of this license with this distribution.

=cut

eval "use Time::HiRes";

if( $@ ) { plan skip_all => "Needs Time::HiRes to time parsing" }

my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

my $parse_fqname = $class . '::parse_plist';
ok( defined &$parse_fqname, "$parse_fqname is defined" );

my $debug = $ENV{PLIST_DEBUG} || 0;

foreach my $file ( @plists ) {
	diag( "Working on $file" ) if $debug;
	unless( open FILE, '<', $file ) {
		fail( "Could not open $file" );
		next;
		}

	my $data = do { local $/; <FILE> };
	close FILE;

	my $b = length $data;

	my $time1 = [ Time::HiRes::gettimeofday() ];
	my $plist = eval { &{$parse_fqname}( $data ) };
	my $error_at = $@;
	$error_at ?
		fail( "Error parsing $file: $error_at" )
			:
		pass( "Parsed $file without a problem" );

	my $time2 = [ Time::HiRes::gettimeofday() ];

	my $elapsed = Time::HiRes::tv_interval( $time1, $time2 );
	diag( "$file [$b bytes] parsed in $elapsed seconds" );

	# All of the test plists have a dict at the top level, except
	# for binary2 and binary_uids.
	isa_ok( $plist, {
		'plists/binary2.plist'		=> 'ARRAY',
		'plists/binary_uids.plist'	=> 'ARRAY',
	    }->{$file} || 'HASH' );
	}

done_testing();
