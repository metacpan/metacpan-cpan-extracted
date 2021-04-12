
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<zip> method of L<LINQ::Iterator>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ qw( LINQ );

my $letters = LINQ [ 'A' .. 'Z' ];
my $numbers = LINQ [ 0 .. 9 ];
my $sprintf = sub { my $fmt = shift; sprintf( $fmt, @_ ) };

is_deeply(
	$letters->zip( $numbers, $sprintf, '%s:%s' )->to_array,
	[qw/ A:0 B:1 C:2 D:3 E:4 F:5 G:6 H:7 I:8 J:9 /],
	'simple zip with a curried argument',
);

is_deeply(
	$numbers->zip( $letters, $sprintf, '%s+%s' )->to_array,
	[qw/ 0+A 1+B 2+C 3+D 4+E 5+F 6+G 7+H 8+I 9+J /],
	'another simple zip, reversing the collections',
);

done_testing;
