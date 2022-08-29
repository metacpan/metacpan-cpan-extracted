=pod

=encoding utf-8

=head1 NAME

01basic.t - initial tests for Hydrogen::*

=head1 PURPOSE

Check that Hydrogen compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use strict;
use warnings;
use Test2::V0;

sub use_ok {
	my ( $module ) = @_;
	ok ( eval( "require $module; 1" ), "use $module" );
}

use_ok('Hydrogen');

use_ok( "Hydrogen::$_" )
	for qw(
		Array     ArrayRef
		Bool
		Code      CodeRef
		Counter
		Hash      HashRef
		Number
		Scalar
		String
	);

use_ok( "Hydrogen::Curry::$_" )
	for qw(
		ArrayRef
		Bool
		CodeRef
		Counter
		HashRef
		Number
		Scalar
		String
	);

use_ok( "Hydrogen::Topic::$_" )
	for qw(
		ArrayRef
		Bool
		CodeRef
		Counter
		HashRef
		Number
		Scalar
		String
	);

done_testing;

