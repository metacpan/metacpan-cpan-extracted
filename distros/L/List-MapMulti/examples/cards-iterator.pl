use 5.010;
use JSON;
use List::MapMulti qw/iterator_multi/;

my @numbers = (2..10, qw/Jack Queen King Ace/);
my @suits   = qw/Clubs Diamonds Hearts Spades/;

my $iter = iterator_multi \@numbers, \@suits;

while (my ($number, $suit) = $iter->())
{
	say "$number of $suit";
	last if $number eq 'King' && $suit eq 'Spades';
}

=head1 DESCRIPTION

Uses C<iterator_multi> to combines a list of numbers with a list of suits,
generating a pack of playing cards.

Shows how C<iterator_multi> allows the use of loop control statements (e.g.
C<last>).

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

