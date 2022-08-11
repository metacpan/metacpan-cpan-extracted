#!/usr/bin/env perl

use Test::More;

=encoding utf8

=head1 NAME

decode_entities.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/decode_entities.t

	# run a single test
	% prove t/decode_entities.t

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

my $parse_fqname = $class . '::parse_plist';

my $array =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>Mimi &amp; Buster</string>
	<string>Buster &quot;Bean&quot;</string>
</array>
</plist>
HERE

use Data::Dumper;

my $plist  = &{$parse_fqname}( $array );
diag( Dumper( $plist ) . "\n" ) if $ENV{DEBUG};

is( $plist->[0]->value, 'Mimi & Buster' );
is( $plist->[1]->value, 'Buster "Bean"' );

done_testing();
