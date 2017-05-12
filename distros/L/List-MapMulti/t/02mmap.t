use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use List::MapMulti;

my @numbers = (2..10, qw/Jack Queen King Ace/);
my @suits   = qw/Clubs Diamonds Hearts Spades/;
my $type;
my @deck1 = mapm { $type = ref $_; "$_[0] of $_[1]" } \@numbers, \@suits;
my @deck2 = do
{
	my @r;
	for my $n (@numbers)
	{
		for my $s (@suits)
		{
			push @r, "$n of $s";
		}
	}
	@r;
};

isa_ok($type, 'List::MapMulti::Iterator');
is_deeply(\@deck1, \@deck2);

=head1 PURPOSE

Checks that C<mapm> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

