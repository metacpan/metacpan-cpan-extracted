#!/usr/bin/env perl

use strict qw(subs vars);
use warnings;

use Test::More;

=encoding utf8

=head1 NAME

parse_plist_fh.t

=head1 SYNOPSIS

	# run all the tests
	% perl Makefile.PL
	% make test

	# run all the tests
	% prove

	# run a single test
	% perl -Ilib t/parse_plist_fh.t

	# run a single test
	% prove t/parse_plist_fh.t

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

my $parse_name = 'parse_plist_fh';
ok( ! defined &$parse_name, "$parse_name is not defined before import" );
$class->import( $parse_name );
ok( defined &$parse_name, "$parse_name is defined after import" );

my $File = "plists/com.apple.systempreferences.plist";

ok( -e $File, "Sample plist file exists" );

########################################################################
{
ok( open( my $fh, '<:encoding(UTF-8)', $File ), "Opened $File with lexical" );

my $plist = &{$parse_name}( $fh );

ok( $plist, "return value is not false" );
isa_ok( $plist, "${class}::dict" );
is( $plist->type, 'dict', 'type key has right value for nested dict' );
test_plist( $plist );
}

########################################################################

{
ok( open( FILE, '<', $File ), "Opened $File with bareword" );

my $plist = &{$parse_name}( \*FILE );

ok( $plist, "return value is not false" );
isa_ok( $plist,"${class}::dict" );
is( $plist->type, 'dict', 'type key has right value for nested dict' );
test_plist( $plist );
}

done_testing();

########################################################################

sub test_plist {
	my $plist = shift;

	my $value = eval { $plist->value->{NSColorPanelMode}->value };
	diag($@) if $@;
	is( $value, 5, "NSColorPanelMode has the right value" );
	}
