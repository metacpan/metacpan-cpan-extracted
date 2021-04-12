
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<sequence_equal> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );

my $lower  = LINQ [qw/ the cat in the hat /];
my $upper  = LINQ [qw/ who ate my red egg /];
my $upper2 = LINQ [qw/ who ate my red egg cake /];
my $other  = LINQ [qw/ who ate my red cake /];

my $equal_lengths = sub { length( $_[0] ) == length( $_[1] ) };

ok(
	$lower->sequence_equal( $upper, $equal_lengths ),
	'sequence which is equal',
);

ok(
	$upper->sequence_equal( $lower, $equal_lengths ),
	'sequence which is equal, inverted',
);

ok(
	!$lower->sequence_equal( $upper2, $equal_lengths ),
	'sequence which is not equal',
);

ok(
	!$upper2->sequence_equal( $lower, $equal_lengths ),
	'sequence which is not equal, inverted',
);

ok(
	!$lower->sequence_equal( $other, $equal_lengths ),
	'sequence which is not equal',
);

ok(
	!$other->sequence_equal( $lower, $equal_lengths ),
	'sequence which is not equal, inverted',
);

my $nums1 = LINQ [ 1 .. 7 ];
my $nums2 = LINQ [ 1 .. 6, 0 ];
my $nums3 = LINQ [ 1 .. 8 ];

ok(
	$nums1->sequence_equal( $nums1 ),
	'numeric sequence which is equal',
);

ok(
	!$nums1->sequence_equal( $nums2 ),
	'numeric sequence which is not equal',
);

ok(
	!$nums1->sequence_equal( $nums3 ),
	'numeric sequence which is not equal',
);

done_testing;
