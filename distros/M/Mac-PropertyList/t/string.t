#!/usr/bin/env perl

use Test::More;

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
	% perl -Ilib t/string.t

	# run a single test
	% prove t/string.t

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

my $type_class = $class . '::string';
my $parse_fqname = $class . '::parse_plist';

subtest empty_object => sub {
	my $string = $type_class->new;
	isa_ok( $string, $type_class, "Make empty object fo $type_class" );
	};

subtest parse => sub {
	my $plist = <<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<string>Mimi</string>
</plist>
HERE

	$plist = &{$parse_fqname}( $plist );
	isa_ok( $plist, $type_class, "Make $type_class object from plist string" );
	};

subtest create => sub {
	$class->import( 'create_from_string' );
	ok( defined &create_from_string );

	my $plist = create_from_string( 'Roscoe' );

	like $plist, qr|<string>Roscoe</string>|, 'Has the string node';
	};

done_testing();
