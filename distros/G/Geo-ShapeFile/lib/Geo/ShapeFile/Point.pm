package Geo::ShapeFile::Point;
# TODO - add dimension operators (to specify if 2 or 3 dimensional point)
use strict;
use warnings;
use Math::Trig 1.04;
use Carp;

our $VERSION = '3.01';

use overload
    '==' => 'eq',
    'eq' => 'eq',
    '""' => 'stringify',
    '+'  => \&add,
    '-'  => \&subtract,
    '*'  => \&multiply,
    '/'  => \&divide,
    fallback => 1,
;

my %config = (
    comp_includes_z => 1,
    comp_includes_m => 1,
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {@_};

    bless $self, $class;

    return $self;
}

sub _var {
    my $self = shift;
    my $var  = shift;

    if (@_) {
        return $self->{$var} = shift;
    }
    else {
        return $self->{$var};
    }
}

#  these could be factory generated
sub X { shift()->_var('X', @_); }
sub Y { shift()->_var('Y', @_); }
sub Z { shift()->_var('Z', @_); }
sub M { shift()->_var('M', @_); }

sub x_min { $_[0]->_var('X'); }
sub x_max { $_[0]->_var('X'); }
sub y_min { $_[0]->_var('Y'); }
sub y_max { $_[0]->_var('Y'); }
sub z_min { $_[0]->_var('Z'); }
sub z_max { $_[0]->_var('Z'); }
sub m_min { $_[0]->_var('M'); }
sub m_max { $_[0]->_var('M'); }

sub get_x { $_[0]->{X} }
sub get_y { $_[0]->{Y} }
sub get_z { $_[0]->{Z} }
sub get_m { $_[0]->{M} }


sub import {
    my $self = shift;
    my %args = @_;

    foreach(keys %args) { $config{$_} = $args{$_}; }
}

sub eq {
    my $left  = shift;
    my $right = shift;

    if ($config{comp_includes_z} && (defined $left->Z || defined $right->Z)) {
        return 0 unless defined $left->Z && defined $right->Z;
        return 0 unless $left->Z == $right->Z;
    }
    if ($config{comp_includes_m} && (defined $left->M || defined $right->M)) {
        return 0 unless defined $left->M && defined $right->M;
        return 0 unless $left->M == $right->M;
    }

    return ($left->X == $right->X && $left->Y == $right->Y);
}

sub stringify {
    my $self = shift;

    my @foo = ();
    foreach(qw/X Y Z M/) {
        if(defined $self->$_()) {
            push @foo, "$_=" . $self->$_();
        }
    }
    my $r = 'Point(' . join(',', @foo) . ')';
}

sub distance_from {
    my ($p1, $p2) = @_;

    my $dp = $p2->subtract($p1);
    return sqrt ( ($dp->X ** 2) + ($dp->Y **2) );
}

sub distance_to { distance_from(@_); }

sub angle_to {
    my ($p1, $p2) = @_;

    my $dp = $p2->subtract ($p1);

    my $x_off = $dp->get_x;
    my $y_off = $dp->get_y;

    return 0 if !($x_off || $y_off);

    my $bearing = 90 - Math::Trig::rad2deg (Math::Trig::atan2 ($y_off, $x_off));
    if ($bearing < 0) {
        $bearing += 360;
    }

    return $bearing;
}

sub add {      _mathemagic('add',      @_); }
sub subtract { _mathemagic('subtract', @_); }
sub multiply { _mathemagic('multiply', @_); }
sub divide {   _mathemagic('divide',   @_); }

sub _mathemagic {
    my ($op, $l, $r, $reverse) = @_;

    if ($reverse) {  # put them back in the right order
        ($l, $r) = ($r, $l);
    }
    my ($left, $right);

    if (UNIVERSAL::isa($l, 'Geo::ShapeFile::Point')) { $left  = 'point'; }
    if (UNIVERSAL::isa($r, 'Geo::ShapeFile::Point')) { $right = 'point'; }

    if ($l =~ /^[\d\.]+$/) { $left  = 'number'; }
    if ($r =~ /^[\d\.]+$/) { $right = 'number'; }

    unless ($left)  { croak "Couldn't identify $l for $op"; }
    unless ($right) { croak "Couldn't identify $r for $op"; }

    my $function = '_' . join '_', $op, $left, $right;

    croak "Don't know how to $op $left and $right"
      if !defined &{$function};

    do {
        no strict 'refs';
        return $function->($l, $r);
    }
}

sub _add_point_point {
    my ($p1, $p2) = @_;

    my $z;
    if(defined($p2->Z) && defined($p1->Z)) { $z = ($p2->Z + $p1->Z); }

    Geo::ShapeFile::Point->new(
        X => ($p2->X + $p1->X),
        Y => ($p2->Y + $p1->Y),
        Z =>  $z,
    );
}

sub _add_point_number {
    my ($p1, $n) = @_;

    my $z;
    if (defined($p1->Z)) { $z = ($p1->Z + $n); }

    Geo::ShapeFile::Point->new(
        X => ($p1->X + $n),
        Y => ($p1->Y + $n),
        Z => $z,
    );
}
sub _add_number_point { add_point_number(@_); }

sub _subtract_point_point {
    my($p1, $p2) = @_;

    my $z;
    if(defined($p2->Z) && defined($p1->Z)) { $z = ($p2->Z - $p1->Z); }

    my $result = Geo::ShapeFile::Point->new(
        X => ($p1->X - $p2->X),
        Y => ($p1->Y - $p2->Y),
        Z =>  $z,
    );
    return $result;
}

sub _subtract_point_number {
    my($p1, $n) = @_;

    my $z;
    if (defined $p1->Z) {
        $z = ($p1->Z - $n);
    }

    Geo::ShapeFile::Point->new(
        X => ($p1->X - $n),
        Y => ($p1->Y - $n),
        Z =>  $z,
    );
}
sub _subtract_number_point { _subtract_point_number(reverse @_); }

sub _multiply_point_point {
    my ($p1, $p2) = @_;

    my $z;
    if (defined $p2->Z and defined $p1->Z) {
        $z = $p2->Z * $p1->Z;
    }

    Geo::ShapeFile::Point->new(
        X => ($p2->X * $p1->X),
        Y => ($p2->Y * $p1->Y),
        Z =>  $z,
    );
}
sub _multiply_point_number {
    my($p1, $n) = @_;

    my $z;
    if (defined $p1->Z) {
        $z = $p1->Z * $n;
    }

    Geo::ShapeFile::Point->new(
        X => ($p1->X * $n),
        Y => ($p1->Y * $n),
        Z =>  $z,
    );
}

sub _multiply_number_point { _multiply_point_number(reverse @_); }

sub _divide_point_point {
    my($p1, $p2) = @_;

    my $z;
    if (defined $p2->Z and defined $p1->Z) {
        $z = $p1->Z / $p2->Z;
    }

    Geo::ShapeFile::Point->new(
        X => ($p1->X / $p2->X),
        Y => ($p1->Y / $p2->Y),
        Z =>  $z,
    );
}

sub _divide_point_number {
    my ($p1, $n) = @_;

    my $z;
    if (defined $p1->Z) {
        $z = $p1->Z / $n;
    }

    Geo::ShapeFile::Point->new(
        X => ($p1->X / $n),
        Y => ($p1->Y / $n),
        Z =>  $z,
    );
}

sub _divide_number_point { divide_point_number(reverse @_); }

1;
__END__
=head1 NAME

Geo::ShapeFile::Point - Geo::ShapeFile utility class.

=head1 SYNOPSIS

  use Geo::ShapeFile::Point;
  use Geo::ShapeFile;

  my $point = Geo::ShapeFile::Point->new(X => 12345, Y => 54321);

=head1 ABSTRACT

  This is a utility class, used by Geo::ShapeFile.

=head1 DESCRIPTION

This is a utility class, used by L<Geo::ShapeFile> to represent point data,
you should see the Geo::ShapeFile documentation for more information.

=head2 EXPORT

Nothing.

=head2 IMPORT NOTE

This module uses overloaded operators to allow you to use == or eq to compare
two point objects.  By default points are considered to be equal only if their
X, Y, Z, and M attributes are equal.  If you want to exclude the Z or M
attributes when comparing, you should use comp_includes_z or comp_includes_m 
when importing the object.  Note that you must do this before you load the
Geo::ShapeFile module, or it will pass it's own arguments to import, and you
will get the default behavior:

  DO:

  use Geo::ShapeFile::Point comp_includes_m => 0, comp_includes_z => 0;
  use Geo::ShapeFile;

  DONT:

  use Geo::ShapeFile;
  use Geo::ShapeFile::Point comp_includes_m => 0, comp_includes_z => 0;
  (Geo::ShapeFile already imported Point for you, so it has no effect here)

=head1 METHODS

=over 4

=item new (X => $x, Y => $y)

Creates a new Geo::ShapeFile::Point object, takes a hash consisting of X, Y, Z,
and/or M values to be assigned to the point.

=item X() Y() Z() M()

Set/retrieve the X, Y, Z, or M values for this object.

=item get_x() get_y() get_z() get_m()

Get the X, Y, Z, or M values for this object.  Slightly faster than the
dual purpose set/retrieve methods so good for heavy usage parts of your code.

=item x_min() x_max() y_min() y_max()

=item z_min() z_max() m_min() m_max()

These methods are provided for compatibility with Geo::ShapeFile::Shape, but
for points simply return the X, Y, Z, or M coordinates as appropriate.

=item distance_from($point)

Returns the distance between this point and the specified point.  Only
considers the two-dimensional distance.  Z and M values are ignored.

=item angle_to($point);

Returns the bearing (in degrees from north) from this point to some other point.  Returns
0 if the two points are in the same location.

=back

=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to
  L<https://github.com/shawnlaffan/Geo-ShapeFile/issues>.

=head1 SEE ALSO

L<Geo::ShapeFile>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2002-2013 by Jason Kohles

Copyright 2014 by Shawn Laffan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
