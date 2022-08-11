#!/usr/bin/env perl

use strict qw(subs vars);
use warnings;

use Test::More;

=encoding utf8

=head1 NAME

as_perl.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/as_perl.t

	# run a single test
	% prove t/as_perl.t

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

use File::Spec::Functions;

my $class = 'Mac::PropertyList::SAX';
my @methods = qw( as_perl );

use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

my $type_class = $class . '::array';
my $parse_fqname = $class . '::parse_plist_file';

my $test_file = catfile( qw( plists the_perl_review.abcdp ) );
ok( -e $test_file, "Test file for binary plist is there" );

{
my $plist = &{$parse_fqname}( $test_file );
isa_ok( $plist, "Mac::PropertyList::dict" );
can_ok( $plist, @methods );

my $perl = $plist->as_perl;
is(
	$perl->{ 'Organization' },
	'The Perl Review',
	'Organization returns the right value'
	);

is(
	$perl->{ 'Organization' },
	'The Perl Review',
	'Shallow access returns the right value'
	);

is(
	$perl->{'Address'}{'values'}[0]{'City'},
	'Chicago',
	'Deep access returns the right value'
	);
}

done_testing();
