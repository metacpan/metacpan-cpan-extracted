package List::Conditional;

use warnings;
use strict;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(clist);

use Carp qw(croak);
use List::MoreUtils qw(natatime);


=head1 NAME

List::Conditional - Create lists based on a condition for each element


=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use List::Conditional;

	# academic example
	my @list = clist(1 => 'a', 0 => 'b', 1 => 'c');
	# same as @list = ('a', 'c');
	
    # a more practical example
	my @things_to_pack = clist(
		    $destination->is_rainy() => 'umbrella',
		    $destination->is_warm()  => 'shorts',
		    $myself->is_sick()       => 'meds',
		    $flight->duration() > 2  => 'pillow',
		    int $myself->children()  => 'toys',
		    ...
	);
	
	
=head1 EXPORT

B<clist> is automatically exported, as it is the only function in this module.


=head1 FUNCTIONS

=head2 clist

B<Arguments:> an even number of elements, interpreted as pairs of C<<condition => value>>

B<Returns:> the list of values, for which the associated condition evaluates to true.

This function provides a nice functional and highly readable approach to conditional list building,
instead of using imperative control structures like C<if> and C<push>
or the ternary operator C<condition ? value : ()>.

Beware that all conditions and values are passed to B<clist> in list context,
and therefore explicitly enforce scalar context for your conditions and values,
as seen in the L</"SYNOPSIS">.

If you want multiple values per condition, you can use L<List::Flatten> as follows:

	use List::Flatten;
	
	my @things_to_pack = flat clist(
		    $destination->is_rainy() => 'umbrella',
		    $destination->is_warm()  => ['shorts', 'sandals'],
		    $myself->is_sick()       => 'meds',
		    $flight->duration() > 2  => 'pillow',
		    int $myself->children()  => ['toys', 'candy'],
		    ...
	);

If you need alternative values in case the conditions do not hold,
then the ternary operator is right for you, not this function.

=cut

sub clist {
	croak "odd number of elements passed to clist, requires (condition => value)-pairs!" if @_ % 2;
	my @result = ();
	my $it = natatime 2, @_;
	while (my ($condition, $element) = $it->()) {
		push @result, $element if $condition;
	}
	return @result;
}


=head1 AUTHOR

Darko Obradovic, C<< <dobradovic at gmx.de> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-list-conditional at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=List-Conditional>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::Conditional


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-Conditional>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-Conditional>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/List-Conditional>

=item * Search CPAN

L<http://search.cpan.org/dist/List-Conditional>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Darko Obradovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
