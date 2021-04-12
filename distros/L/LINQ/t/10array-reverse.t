
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<reverse> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );

my $c = LINQ [
	{ foo => 9 },
	{ foo => 8 },
	{ foo => 7 },
	{ foo => 56 },
	{ foo => 1234 },
];

is_deeply(
	$c->reverse->to_array,
	[ reverse( $c->to_list ) ],
);

done_testing;
