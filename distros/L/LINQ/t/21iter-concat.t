
=pod

=encoding utf-8

=head1 PURPOSE

Concatenates an infinite collection with a finite one.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ qw( Range Repeat );

is_deeply(
	Range( 1, 7 )->concat( Repeat( 8 ) )->take( 10 )->to_array,
	[ 1 .. 7, ( 8 ) x 3 ],
	'Range( 1, 7 )->concat( Repeat( 8 ) )->take( 10 )'
);

is_deeply(
	Repeat( 8 )->concat( Range( 1, 7 ) )->take( 10 )->to_array,
	[ ( 8 ) x 10 ],
	'Repeat( 8 )->concat( Range( 1, 7 ) )->take( 10 )'
);

done_testing;
