use 5.010;
use List::MapMulti qw/mapm/;

my @numbers = (2..10, qw/Jack Queen King Ace/);
my @suits   = qw/Clubs Diamonds Hearts Spades/;

say $_ for mapm { "$_[0] of $_[1]" } \@numbers, \@suits;

=head1 DESCRIPTION

Uses C<mapm> to combines a list of numbers with a list of suits, generating
a pack of playing cards.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

