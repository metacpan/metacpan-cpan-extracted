package Math::MagicSquare::Generator;
use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '0.01';

sub _sum {
    my $sum = 0;
    $sum += $_ for @_;
    return $sum
}

sub new {
    my ($class, %opt) = @_;
    $opt{size}  ||= 5;
    $opt{start} ||= 1;
    $opt{step}  ||= 1;
    croak "Size needs to be a positive, odd integer"
	unless $opt{size} > 0 and
	       $opt{size} % 2 and
	       $opt{size} == int($opt{size});  
    my $self = [
	map {
	    [ (undef) x $opt{size} ]
	} 1..$opt{size}
    ];
    my $value = $opt{start};
    my $halv = int(@$self / 2);
    for my $start_x (-$halv..$halv) {
	my $x = $start_x - 1;
	my $y = $x + @$self + 1;
	for (1 .. @$self) {
	    $x = $x - @$self if ++$x > $#$self;
	    $y = $y - @$self if --$y > $#$self;
	    $self->[$y][$x] = $value;
	    $value += $opt{step};
	}
    }
    return bless $self, $class;
}

sub hflip {
    my ($self) = @_;
    my $clone;
    push @$clone, [ reverse @$_ ] for @$self;
    return bless $clone, ref $self;
}

sub vflip {
    my ($self) = @_;
    my $clone;
    push @$clone, [ @$_ ] for reverse @$self;
    return bless $clone, ref $self;
}

sub sum {
    my ($self) = @_;
    return _sum( @{ $self->[0] } );
}

sub check {
    my ($self) = @_;
    my $sum = $self->sum;
    # Horizontals
    for (@$self[1..$#$self]) {
	return undef if @$_ > @$self; # undef if not square
	return undef if _sum(@$_) != $sum;
    }
    # Verticals
    for my $x (0..$#$self) {
	return undef if _sum(map $self->[$_][$x], 0..$#$self) != $sum;
    }
    # Diagonals
    return undef if _sum(map $self->[$_][$_],           0..$#$self) != $sum;
    return undef if _sum(map $self->[$#$self - $_][$_], 0..$#$self) != $sum;
    # Duplicates
    my %seen;
    $seen{$_}++ for map @$_, @$self;
    return undef if _sum(values %seen) != keys %seen;
    # Passed all tests!
    return $sum;
}

sub as_string {
    my ($self) = @_;
    my $max = 0;
    length > $max and $max = length for map @$_, @$self;
    return map { join(' ', map {' 'x($max - length) . $_} @$_) . "\n" } @$self;
}

sub as_html {
    my ($self) = @_;
    return "<table>\n" . join("\n",
	map { '<tr><td>' . join('</td><td>', @$_) . '</td></tr>' } @$self) .
	"\n</table>\n";
}

sub as_csv {
    my ($self) = @_;
    return join("\n", map { join ',', @$_ } @$self) . "\n";
}

1;

__END__

=head1 NAME

Math::MagicSquare::Generator - Magic Square Generator

=head1 SYNOPSIS

    use Math::MagicSquare::Generator

    my $square = Math::MagicSquare::Generator->new(size => 5,
                                                   step => 3,
						   start=> 6);
    for ($square, $square->vflip, $square->hflip) {
	print $_->as_string;
	print "-----\n";
    }

    $square->[0][0] = -15; # Break magic :)
    print $square->check ? "Magic square\n" : "Just a square\n";

    print '<html><body>';
    print Math::MagicSquare::Generator->new->hflip->vflip->as_html;
    print '</body></html>';

=head1 DESCRIPTION

This module creates magic squares. A magic square is a square in which
all numbers are different and the sums of all rows, all columns and
the two diagonals are equal.
Math::MagicSquare::Generator cannot create panmagic squares, or squares
that have an even size. (A panmagic square is magic square where the
"wrapped" diagonals are also equal.)

=head1 EXAMPLE

     3 16  9 22 15  This square is the output of
    20  8 21 14  2  print Math::MagicSquare::Generator->new->as_string;
     7 25 13  1 19
    24 12  5 18  6
    11  4 17 10 23

    The sums of the rows are 65.
    The sums of the columns are 65.
    The sums of the diagonals are 65.

=head1 METHODS

=over 10

=item new

The constructor that generates the square immediately. It
creates an object using the given named arguments. Valid arguments are
C<size>, C<step> and C<start>. C<size> has to be positive, odd and
integer.

=item check

A checker - returns the common sum if the square is magic, or undef if
it's not. Because the sum can never be 0, you can use this as a boolean
value. (Well, the sum in a 1x1 square can be 0, if the single number is
0.) You can use this method to check if the square has been tampered with.

=item sum

Returns the common sum of the rows, columns and diagonals.

=item vflip, hflip

These methods return a vertically or horizontally flipped clone of the
square. The clone is a Math::MagicSquare::Generator, so stacking these
methods is possible.

=item as_string, as_html, as_csv

DWYM - return the square as a formatted string, piece of html or in
CSV format.

=back

=head1 THIS MODULE AND Math::MagicSquare

Math::MagicSquare is a module that checks if a square is magical. It
takes a list in its C<new> method, so you'll have to dereference the
generated square:

    use Math::MagicSquare;
    use Math::MagicSquare::Generator;

    my $square = Math::MagicSquare::Generator->new;
    print Math::MagicSquare->new( @$square )->check, "\n"; # 2

Its C<check> will always return 2 for squares generated using this
module (or 3 if it's a 1x1 square).

=head1 KNOWN BUGS

None yet.

=head1 AUTHOR

Juerd <juerd@juerd.nl>

=cut
