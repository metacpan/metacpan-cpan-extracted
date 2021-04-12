
=pod

=encoding utf-8

=head1 PURPOSE

Random exception-related tests.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ;
use LINQ::Exception;

# line 1 "09exceptional.t-test1"
{
	my $e = exception { 'LINQ::Exception'->throw };

	object_ok(
		$e, '$e',
		isa  => 'LINQ::Exception',
		can  => [ qw/ message package file line to_string / ],
		more => sub {
			my $e = shift;
			is( $e->message, 'An error occurred' );
			is( $e->package, 'main' );
			is( $e->file,    '09exceptional.t-test1' );
			is( $e->line,    2 );
		},
	);
}

{
	my $e = exception { 'LINQ::Exception::CallerError'->throw };

	object_ok(
		$e, '$e',
		isa  => 'LINQ::Exception::InternalError',
		can  => [ qw/ message package file line to_string / ],
		more => sub {
			my $e = shift;
			like( $e->message, qr/Required attribute "message" not defined/ );
		},
	);
}

{
	my $e = exception { 'LINQ::Exception::CollectionError'->throw };

	object_ok(
		$e, '$e',
		isa  => 'LINQ::Exception::InternalError',
		can  => [ qw/ message package file line to_string / ],
		more => sub {
			my $e = shift;
			like( $e->message, qr/Required attribute "collection" not defined/ );
		},
	);
}

{
	my $e = exception { 'LINQ::Exception::Cast'->throw };

	object_ok(
		$e, '$e',
		isa  => 'LINQ::Exception::InternalError',
		can  => [ qw/ message package file line to_string / ],
		more => sub {
			my $e = shift;
			like( $e->message, qr/Required attribute "collection" not defined/ );
		},
	);
}

{
	my $e = exception { 'LINQ::Exception::Cast'->throw( collection => LINQ::LINQ( [] ) ) };

	object_ok(
		$e, '$e',
		isa  => 'LINQ::Exception::InternalError',
		can  => [ qw/ message package file line to_string / ],
		more => sub {
			my $e = shift;
			like( $e->message, qr/Required attribute "type" not defined/ );
		},
	);
}

done_testing;
