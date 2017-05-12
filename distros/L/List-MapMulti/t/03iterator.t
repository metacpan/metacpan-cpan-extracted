use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use List::MapMulti 'iterator_multi';

my @numbers = (2..10, qw/Jack Queen King Ace/);
my @suits   = qw/Clubs Diamonds Hearts Spades/;

my $expected = join('|', (grep {length} map {chomp($_);$_} <DATA>), q[]);
my $got  = '';
my $iter = iterator_multi \@numbers, \@suits;
while (my ($n, $s) = $iter->())
{
	$got .= "$n of $s|";

	if ($n eq 6 and $s eq 'Hearts')
	{
		is_deeply(
			[$iter->current_indices],
			[4, 2],
		);
	}

	if ($n eq 'Queen')
	{
		$iter->next_indices(11,2);
	}
	if ($n eq 'Jack')
	{
		my @curr = $iter->current;
		$iter->current('Knave', $curr[1]);
	}
}

is($got, $expected);

=head1 PURPOSE

Checks that C<iterator_multi> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
2 of Clubs
2 of Diamonds
2 of Hearts
2 of Spades
3 of Clubs
3 of Diamonds
3 of Hearts
3 of Spades
4 of Clubs
4 of Diamonds
4 of Hearts
4 of Spades
5 of Clubs
5 of Diamonds
5 of Hearts
5 of Spades
6 of Clubs
6 of Diamonds
6 of Hearts
6 of Spades
7 of Clubs
7 of Diamonds
7 of Hearts
7 of Spades
8 of Clubs
8 of Diamonds
8 of Hearts
8 of Spades
9 of Clubs
9 of Diamonds
9 of Hearts
9 of Spades
10 of Clubs
10 of Diamonds
10 of Hearts
10 of Spades
Jack of Clubs
Knave of Diamonds
Knave of Hearts
Knave of Spades
Queen of Clubs
King of Hearts
King of Spades
Ace of Clubs
Ace of Diamonds
Ace of Hearts
Ace of Spades
