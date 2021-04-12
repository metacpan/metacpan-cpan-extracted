
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<concat> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );

is_deeply(
	( LINQ [ 1 .. 4 ] )->concat( LINQ [ 5 .. 8 ] )->to_array,
	[ 1 .. 8 ],
	'simple concat',
);

is_deeply(
	( LINQ [ 1 .. 8 ] )->concat( LINQ [] )->to_array,
	[ 1 .. 8 ],
	'concat with empty tail',
);

is_deeply(
	( LINQ [] )->concat( LINQ [ 1 .. 8 ] )->to_array,
	[ 1 .. 8 ],
	'concat with empty head',
);

done_testing;
