=pod

=encoding utf-8

=head1 PURPOSE

Test for RT#101024.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

BEGIN {
	package AAA;
	
	sub new { bless {}, shift }
	
	use Lexical::Accessor;
	
	lexical_has attr => (
		accessor => \my $attr,
		default  => sub { 90 },
	);
	
	sub get { shift->$attr }
};

is( AAA->new->get, 90 );

done_testing;

