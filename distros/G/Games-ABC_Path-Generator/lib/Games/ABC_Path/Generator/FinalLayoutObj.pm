package Games::ABC_Path::Generator::FinalLayoutObj;

use 5.006;

use strict;
use warnings;

use integer;

use base 'Games::ABC_Path::Generator::Base';

use Games::ABC_Path::Solver::Constants;

=head1 NAME

Games::ABC_Path::Generator::FinalLayoutObj - represents a final layout.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Games::ABC_Path::Generator;

    my $gen = Games::ABC_Path::Generator->new({seed => 1});

    # Returns a Games::ABC_Path::Generator::FinalLayoutObj object.
    my $layout = $gen->calc_final_layout();

    my $A_xy = $layout->get_A_xy();

=head1 SUBROUTINES/METHODS

=head2 my $layout = Games::ABC_Path::Generator::FinalLayoutObj->new({%args});

Initializes a new layout. B<For internal use.>.

=cut

sub _s
{
    my $self = shift;

    if (@_)
    {
        $self->{_s} = shift;
    }

    return $self->{_s};
}

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->_s($args->{layout_string});

    return;
}

=head2 $layout->get_A_pos()

Returns the position of the letter 'A'.

=cut

sub get_A_pos
{
    my ($self) = @_;

    return index($self->_s, chr(1));
}

=head2 $layout->get_A_xy()

Returns the (X,Y) coordinates of the letter A as a C<< {x => $x, y => $y} >>
hash reference.

=cut

sub get_A_xy
{
    my ($self) = @_;

    my ($y, $x) = $self->_to_xy($self->get_A_pos());

    return {y => $y, x => $x,};
}

=head2 $layout->get_cell_contents($index)

Returns the cell at index L<$index> (where index is C< $Y*5 + $X>).

=cut

sub get_cell_contents
{
    my ($self, $index) = @_;

    return vec($self->_s, $index, 8) ;
}

=head2 my $letter = $layout->get_letter_at_pos({y => $y, x => $x});

Returns the letter at $y and $x .

=cut

sub get_letter_at_pos
{
    my ($self, $pos) = @_;

    return $letters[
        $self->get_cell_contents(
            $self->_xy_to_int(
                [$pos->{'y'},$pos->{'x'}],
            )
        )-1,
    ];
}

=head2 $layout->as_string($args);

Represents the layout as string.

=cut

sub as_string
{
    my ($l, $args) = @_;

    my $render_row = sub {
        my $y = shift;

        return join(" | ",
            map {
                my $x = $_;
                my $v = $l->get_cell_contents($l->_xy_to_int([$y,$x]));
            $v ? $letters[$v-1] : '*' } (0 .. $LEN - 1));
    };

    return join('', map { $render_row->($_) . "\n" } (0 .. $LEN-1));
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-abc_path-generator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-ABC_Path-Generator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::ABC_Path::Generator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-ABC_Path-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-ABC_Path-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-ABC_Path-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-ABC_Path-Generator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Games::ABC_Path::Generator
