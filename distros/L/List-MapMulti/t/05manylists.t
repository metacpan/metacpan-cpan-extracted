use strict;
use warnings FATAL => 'all';
use Test::More;

use List::MapMulti;

my @numbers = ( 2 .. 10, qw< J Q K A > );
my @suits   = qw< Spades Hearts Diamonds Clubs >;
my @packs   = qw< Pack_1 Pack_2 Pack_3 Pack_4 Pack_5 >;

sub traditional ()
{
	my @results;
	for my $number (@numbers)
	{
		for my $suit (@suits)
		{
			for my $pack (@packs)
			{
				push @results, "$number of $suit from $pack";
			}
		}
	}
	\@results;
}

sub mapmulti_params ()
{
	[ mapm { "$_[0] of $_[1] from $_[2]" } \@numbers, \@suits, \@packs ]
}

while (@packs)
{
	pop @packs;
	is_deeply mapmulti_params, traditional;
}

done_testing;


=head1 PURPOSE

The other tests all seem to only involve two lists; List::MapMulti is
supposed to work with an arbitrary number, so let's test with more.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

