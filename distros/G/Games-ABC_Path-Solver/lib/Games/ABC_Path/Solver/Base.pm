package Games::ABC_Path::Solver::Base;

use warnings;
use strict;

use Games::ABC_Path::Solver::Constants;

=head1 NAME

Games::ABC_Path::Solver::Base - base class for Games::ABC_Path::Solver classes.

=head1 VERSION

Version 0.4.1

=cut

our $VERSION = '0.4.1';

=head1 SYNOPSIS

    use base 'Games::ABC_Path::Solver::Base';

    sub _init
    {

    }

=head1 FUNCTIONS

=head2 new

The default constructor - construct an object and calls _init.

=cut

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

use integer;

sub _xy_to_int
{
    my ($self, $xy) = @_;

=begin foo

    {
    my ($y, $x) = @{$xy}[$Y,$X];
    if (($x < 0) or ($x > $LEN_LIM))
    {
        confess "X $x out of range.";
    }

    if (($y < 0) or ($y > $LEN_LIM))
    {
        confess "Y $y out of range.";
    }
    }
=end foo

=cut

    return $xy->[$Y] * $LEN + $xy->[$X];
}

sub _to_xy
{
    my ($self, $int) = @_;

    return (($int / $LEN), ($int % $LEN));
}

sub _y_indexes
{
    return (0 .. $LEN_LIM);
}

sub _x_indexes
{
    return (0 .. $LEN_LIM);
}

sub _x_in_range
{
    my ($self, $x) = @_;

    return ($x >= 0 and $x < $LEN);
}

sub _y_in_range
{
    my ($self, $y) = @_;

    return $self->_x_in_range($y);
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-abc_path-solver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-ABC_Path-Solver>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::ABC_Path::Solver::Base


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-ABC_Path-Solver>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-ABC_Path-Solver>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-ABC_Path-Solver>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-ABC_Path-Solver/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Shlomi Fish.

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

1; # End of Games::ABC_Path::Solver::Base
