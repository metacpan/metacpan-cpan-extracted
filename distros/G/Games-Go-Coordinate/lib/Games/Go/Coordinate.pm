use 5.008;
use strict;
use warnings;

package Games::Go::Coordinate;
our $VERSION = '1.100860';
# ABSTRACT: Represents a board coordinate in the game of Go
use Moose;
use overload
  '""'  => 'stringify',
  'cmp' => 'str_cmp';
has [qw/x y/] => (is => 'rw', isa => 'Int');

# accept something like 'ac' and set x=1, y=3
sub set_sgf_coordinate {
    my ($self, $coord) = @_;
    my ($x, $y) = map { ord($_) - 96 } split // => lc($coord);
    $self->x($x);
    $self->y($y);
}

sub new_from_sgf_coordinate {
    my ($class, $coord) = @_;
    my $self = $class->new;
    $self->set_sgf_coordinate($coord);
    $self;
}

sub to_sgf {
    my $self = shift;
    join '' => map { chr($_ + 96) } $self->x, $self->y;
}

sub as_list {
    my $self = shift;
    sprintf '(%d,%d)', $self->x, $self->y;
}

sub stringify {
    my $self = shift;
    $self->to_sgf;
}

sub str_cmp {
    my ($lhs, $rhs, $reversed) = @_;
    $_ = "$_" for $lhs, $rhs;
    ($lhs, $rhs) = ($rhs, $lhs) if $reversed;
    $lhs cmp $rhs;
}

sub translate {
    my ($self, $dx, $dy) = @_;
    $self->x($self->x + $dx);
    $self->y($self->y + $dy);
}
1;


__END__
=pod

=for stopwords SGF

=head1 NAME

Games::Go::Coordinate - Represents a board coordinate in the game of Go

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    use Games::Go::Coordinate;

    my $c1 = Games::Go::Coordinate->new(x => 4, y => 3);
    my $c2 = Games::Go::Coordinate->new(x => 4, y => 10);
    if ($c2 gt $c1) {
        # ...
    }

=head1 DESCRIPTION

This class represents a board coordinate in the game of Go. Coordinate objects
can be compared (as strings) to see whether two ranks are equal or whether one
rank is higher than the other. Coordinate objects stringify to the SGF
notation (for example, C<(4,10)> stringifies to C<dj>.

=head1 METHODS

=head2 set_sgf_coordinate

    $coord->set_sgf_coordinate('cf');

Takes a coordinate in SGF notation and sets C<x()> and C<y()> from it.

=head2 new_from_sgf_coordinate

    my $cord = Games::Go::Coordinate->new_from_sgf_coordinate('cf');

Alternative constructor that accepts an SGF coordinate and sets C<x()> and
C<y()> from it.

=head2 to_sgf

Returns the coordinate in SGF notation. This is also how the coordinate object
stringifies.

=head2 as_list

Returns the coordinate in C<(x,y)> notation. For example, it might return a
string C<(16,17)>.

=head2 translate

    $coord->translate(2, -3);

Takes as arguments - in that order - a horizontal delta and a vertical delta
and translates the coordinate by those deltas.

=head2 str_cmp

FIXME

=head2 stringify

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Games-Go-Coordinate>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Games-Go-Coordinate/>.

The development version lives at
L<http://github.com/hanekomu/Games-Go-Coordinate/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

