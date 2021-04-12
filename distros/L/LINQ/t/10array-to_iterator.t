
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<to_iterator> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );
use DisneyData qw( people );

my $BY_ATTRIBUTE = sub {
	my $attr = shift;
	$_->$attr;
};

my $iter = people->select( $BY_ATTRIBUTE, 'name' )->to_iterator;

my @names;
while ( my ( $name ) = $iter->() ) {
	push @names, $name;
}

is_deeply(
	\@names,
	[qw/ Anna Elsa Kristoff Sophia Rapunzel /],
	'to_iterator worked'
);

done_testing;
