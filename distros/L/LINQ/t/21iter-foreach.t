
=pod

=encoding utf-8

=head1 PURPOSE

Test C<foreach> on an infinite collection.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ qw( LINQ );

my $output = '';

my $collection = LINQ::Range( 1 );

$collection->foreach(
	sub {
		LINQ::LAST if $_ == 10;
		$output .= $_;
	}
);

is( $output, '123456789' );

my $e = exception { LINQ::LAST };
is(
	ref( $e ),
	'LINQ::Exception::CallerError',
	'correct exception thrown',
);

done_testing;
