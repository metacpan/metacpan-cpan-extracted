#!/usr/bin/env perl

use Test::More;
use File::Spec::Functions qw(catfile);

=encoding utf8

=head1 NAME

string.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/round-trip.t

	# run a single test
	% prove t/round-trip.t

=head1 AUTHORS

Original author: brian d foy C<< <briandfoy@pobox.com> >>

=head1 SOURCE

This file was originally in https://github.com/briandfoy/mac-propertylist

=head1 COPYRIGHT

Copyright © 2025, brian d foy, C<< <briandfoy@pobox.com> >>

=head1 LICENSE

This file is licenses under the Artistic License 2.0. You should have
received a copy of this license with this distribution.

=cut

use lib qw(blib/lib lib);
my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );
$class->import( qw(parse_plist_file plist_as_string) );

my $dir = 'plists';
my @files = map { catfile $dir, $_ } qw( entities.plist entities-dict.plist );

subtest 'files' => sub {
	foreach my $file ( @files ) {
		subtest $file => sub {
			my $contents = do {
				ok open(my $fh, '<:raw', $file), "opened $file";
				local $/;
				<$fh>;
				};
			ok length $contents, "there are contents";
			my $data  = eval { parse_plist_file( $file ) } or diag "ERROR(parse_plist_file): $@";
			ok defined $data, "parse_plist_file returned something" or return;

			my $string = eval{ plist_as_string( $data ) } or diag "ERROR(plist_as_string): $@";
			ok defined $string, "plist_as_string returned something";
			is $string, $contents;
			};
		}
	};

done_testing();
