use strict;
use warnings FATAL => 'all';
use Test::More;

use List::MapMulti;

my @numbers = ( 2 .. 10, qw< J Q K A > );
my @suits   = qw< Spades Hearts Diamonds Clubs >;

sub traditional ()
{
	my @results;
	for my $number (@numbers)
	{
		for my $suit (@suits)
		{
			push @results, "$number of $suit";
		}
	}
	\@results;
}

sub mapmulti_params ()
{
	[ mapm { "$_[0] of $_[1]" } \@numbers, \@suits ]
}

sub mapmulti_ab ()
{
	our ($a, $b);
	[ mapm { "$a of $b" } \@numbers, \@suits ]
}

is_deeply mapmulti_params, traditional;
is_deeply mapmulti_ab, traditional;

done_testing;

=head1 PURPOSE

Checks that C<< $a >> and C<< $b >> work in C<mapm>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
