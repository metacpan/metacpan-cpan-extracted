#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Language::Befunge::Storage::2D::Sparse;
# ABSTRACT: a 2D storage, using sparse hash
$Language::Befunge::Storage::2D::Sparse::VERSION = '5.000';
use Carp;
use aliased 'Language::Befunge::Vector' => 'LBV';
use Readonly;

use base qw{ Language::Befunge::Storage };

use Class::XSAccessor
    accessors => {
        _storage => '_storage',
        _xmin    => '_xmin',
        _xmax    => '_xmax',
        _ymin    => '_ymin',
        _ymax    => '_ymax',
    };

Readonly my $SPACE => ' ';


# -- CONSTRUCTOR

#
# my $storage = LBS::2D::Sparse->new;
#
# Create a new storage.
#
sub new {
    my ($class, $dims) = @_;
    $dims //= 2;
    croak("$class is only useful for 2-dimensional storage.")
        unless $dims == 2;
    my $self    = {};
    bless $self, $class;
    $self->clear;
    return $self;
}



# -- PUBLIC METHODS

#- storage update

#
# $storage->clear;
#
# Clear the storage.
#
sub clear {
    my ($self) = @_;
    $self->_xmin(0);
    $self->_xmax(0);
    $self->_ymin(0);
    $self->_ymax(0);
    $self->_storage( {} );
}


#
# my $size = $storage->store_binary( $code [, $position] );
#
# Store the given $code at the specified $position (defaulting to the
# origin coordinates).
#
# Return the size of the code inserted, as a vector.
#
# The code is a string, representing a block of Funge code. This is
# binary insertion, that is, EOL sequences are stored in Funge-space
# instead of causing the dimension counters to be resetted and
# incremented.
#
sub store_binary {
    my ($self, $code, $position) = @_;

    my $offset = $position;
    $offset    = LBV->new(0,0) unless defined $offset;
    my $x      = $offset->get_component(0);
    my $y      = $offset->get_component(1);
    my $href   = $self->_storage;

    # enlarge min values if needed
    $self->_xmin($x) if $self->_xmin > $x;
    $self->_ymin($y) if $self->_ymin > $y;

    # store data
    foreach my $chr ( split //, $code ) {
        $href->{"$x,$y"} = ord $chr
            unless $chr eq $SPACE; # spaces do not overwrite - cf befunge specs
        $x++;
    }

    # enlarge max values if needed
    $x--; # one step too far
    $self->_xmax($x) if $self->_xmax < $x;
    $self->_ymax($y) if $self->_ymax < $y;

    return LBV->new(length $code, 1);
}


#
# my $size = $storage->store( $code [, $position] );
#
# Store the given $code at the specified $position (defaulting to the
# origin coordinates).
#
# Return the size of the code inserted, as a vector.
#
# The code is a string, representing a block of Funge code. Rows are
# separated by newlines.
#
sub store {
    my ($self, $code, $position) = @_;

    my $offset = $position;
    $offset    = LBV->new(0,0) unless defined $offset;
    my $dy     = LBV->new(0,1);

    # support for any eol convention
    $code =~ s/\r\n/\n/g;
    $code =~ s/\r/\n/g;
    my @lines = split /\n/, $code;

    # store data
    my $maxlen = 0;
    foreach my $line ( @lines ) {
        $maxlen = length($line) if $maxlen < length($line);
        $self->store_binary( $line, $offset );
        $offset += $dy;
    }

    return LBV->new($maxlen, scalar(@lines));
}


# $storage->set_value( $offset, $value );
#
# Write the supplied $value in the storage at the specified $offset.
#
# /!\ As in Befunge, code and data share the same playfield, the
# number stored can be either an instruction or raw data (or even
# both... Eh, that's Befunge! :o) ).
#
sub set_value {
    my ($self, $v, $val) = @_;
    my ($x, $y) = $v->get_all_components();

    # ensure we can set the value.
    $self->_xmin($x) if $self->_xmin > $x;
    $self->_xmax($x) if $self->_xmax < $x;
    $self->_ymin($y) if $self->_ymin > $y;
    $self->_ymax($y) if $self->_ymax < $y;
    $self->_storage->{"$x,$y"} = $val;
}



#- data retrieval

#
# my $dims = $storage->get_dims;
#
# Return the dimensionality of the storage.  For this module, the value is
# always 2.
#
sub get_dims { 2 }


#
# my $vmin = $storage->min;
#
# Return a LBV pointing to the lower bounds of the storage.
#
sub min {
    my ($self) = @_;
    return LBV->new($self->_xmin, $self->_ymin);
}


#
# my $vmax = $storage->max;
#
# Return a LBV pointing to the upper bounds of the storage.
#
sub max {
    my ($self) = @_;
    return LBV->new($self->_xmax, $self->_ymax);
}


#
# my $val = $storage->get_value( $offset );
#
# Return the number stored in the torus at the specified $offset. If
# the value hasn't yet been set, it defaults to the ordinal value of a
# space (ie, #32).
#
# /!\ As in Befunge, code and data share the same playfield, the
# number returned can be either an instruction or raw data (or even
# both... Eh, that's Befunge! :o) ).
#
sub get_value {
    my ($self, $v) = @_;
    my ($x, $y) = $v->get_all_components;
    my $href    = $self->_storage;
    return exists $href->{"$x,$y"}
        ? $href->{"$x,$y"}
        : 32;
}


#
# my $chr = $storage->get_char( $offset );
#
# Return the character stored in the torus at the specified $offset. If
# the value is not between 0 and 255 (inclusive), get_char will return a
# string that looks like "<np-0x4500>".
#
# /!\ As in Befunge, code and data share the same playfield, the
# character returned can be either an instruction or raw data. No
# guarantee is made that the return value is printable.
#
sub get_char {
    my ($self, $v) = @_;
    return chr $self->get_value($v);
}


#
# my $str = $storage->rectangle( $pos, $size );
#
# Return a string containing the data/code in the rectangle defined by
# the supplied vectors.
#
sub rectangle {
    my ($self, $start, $size) = @_;
    my ($x, $y) = $start->get_all_components();
    my ($w, $h) =  $size->get_all_components();

    # retrieve data
    my @lines = ();
    foreach my $j ( $y .. $y+$h-1 ) {
        my $line = join '', map { $self->get_char( LBV->new($_,$j) ) } $x .. $x+$w-1;
        push @lines, $line;
    }

    return join "\n", @lines;
}


#- misc methods

#
# my $href = $storage->labels_lookup;
#
# Parse the storage to find sequences such as ";:(\w[^\s;])[^;]*;"
# and return a hash reference whose keys are the labels and the values
# an anonymous array with four values: a vector describing the absolute
# position of the character just after the trailing ";", and a
# vector describing the velocity that leads to this label.
#
# This method will only look in the four cardinal directions, and does
# wrap basically like befunge93 (however, this should not be a problem
# since we're only using cardinal directions)
#
# This allow to define some labels in the source code, to be used by
# Inline::Befunge (and maybe some exstensions).
#
sub labels_lookup {
    my ($self) = @_;
    my $labels = {}; # result

    # lexicalled to improve speed
    my $xmin = $self->_xmin;
    my $xmax = $self->_xmax;
    my $ymin = $self->_ymin;
    my $ymax = $self->_ymax;

    Y: foreach my $y ( $ymin .. $ymax ) {
        X: foreach my $x ( $xmin .. $xmax ) {
            next X unless $self->get_value(LBV->new($x,$y)) eq ord(';');
            # found a semicolon, let's try...
            VEC: foreach my $vec ( [1,0], [-1,0], [0,1], [0,-1] ) {
                my ($label, $labx, $laby) = $self->_labels_try( $x, $y, @$vec );
                defined($label) or next VEC;

                # how exciting, we found a label!
                exists $labels->{$label}
                    and croak "Help! I found two labels '$label' in the funge space";
                $labels->{$label} = [
                    Language::Befunge::Vector->new($labx, $laby),
                    Language::Befunge::Vector->new(@$vec)
                ];
            }
        }
    }

    return $labels;
}


# -- PRIVATE METHODS

#
# $storage->_labels_try( $x, $y, $dx, $dy )
#
# Try in the specified direction if the funge space matches a label
# definition. Return undef if it wasn't a label definition, or the name
# of the label if it was a valid label.
#
sub _labels_try {
    my ($self, $x, $y, $dx, $dy) = @_;
    my $comment = '';

    my $xmin = $self->_xmin;
    my $xmax = $self->_xmax;
    my $ymin = $self->_ymin;
    my $ymax = $self->_ymax;

    # fetch the whole comment stuff.
    do {
        # calculate the next cell coordinates.
        $x += $dx; $y += $dy;
        $x = $xmin if $xmax < $x;
        $x = $xmax if $xmin > $x;
        $y = $ymin if $ymax < $y;
        $y = $ymax if $ymin > $y;
        my $vec = LBV->new($x,$y);
        $comment .= $self->get_char($vec);
    } while ( $comment !~ /;.$/ );

    # check if the comment matches the pattern.
    $comment =~ /^:(\w[^\s;]*)[^;]*;.$/;
    return ($1, $x, $y);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Storage::2D::Sparse - a 2D storage, using sparse hash

=head1 VERSION

version 5.000

=head1 SYNOPSIS

    my $storage = Language::Befunge::Storage::2D::Sparse->new;
    $storage->clear;
    $storage->store(<<EOF);
    12345
    67890
    EOF

=head1 DESCRIPTION

This class implements a storage as defined in LBS. It makes the
assumption that we're in a 2D Funge space for efficiency reasons.
Therefore, it's only suited for befunge programs.

This storage is sparse, using a private hash with keys such as "$x,$y".
Any value of a non-existing key defaults to 32 (space), as defined by
funge specs.

=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item my $storage = LBS::2D::Sparse->new;

Create a new LBS object.

=back

=head2 Storage update

=over 4

=item $storage->clear;

Clear the storage.

=item my $size = $storage->store_binary( $code [, $position] );

Store the given C<$code> at the specified C<$position> (defaulting to
the origin coordinates).

Return the size of the code inserted, as a vector.

The code is a string, representing a block of Funge code. This is binary
insertion, that is, EOL sequences are stored in Funge-space instead of
causing the dimension counters to be resetted and incremented.

=item my $size = $storage->store( $code [, $position] );

Store the given $code at the specified $position (defaulting to the
origin coordinates).

Return the size of the code inserted, as a vector.

The code is a string, representing a block of Funge code. Rows are
separated by newlines.

=item $storage->set_value( $offset, $value );

Write the supplied C<$value> in the storage at the specified C<$offset>.

B</!\> As in Befunge, code and data share the same playfield, the number
stored can be either an instruction B<or> raw data (or even both... Eh,
that's Befunge! :o) ).

=back

=head2 Data retrieval

=over 4

=item my $dims = $storage->get_dims;

Return the dimensionality of the storage.  For this module, the value is
always 2.

=item my $vmin = $storage->min;

Return a LBV pointing to the lower bounds of the storage.

=item my $vmax = $storage->max;

Return a LBV pointing to the upper bounds of the storage.

=item my $val = $storage->get_value( $offset );

Return the number stored in the torus at the specified C<$offset>. If
the value hasn't yet been set, it defaults to the ordinal value of a
space (ie, #32).

B</!\> As in Befunge, code and data share the same playfield, the number
returned can be either an instruction B<or> raw data (or even both... Eh,
that's Befunge! :o) ).

=item my $chr = $storage->get_char( $offset )

Return the character stored in the torus at the specified C<$offset>. If
the value is not between 0 and 255 (inclusive), get_char will return a
string that looks like C<< <np-0x4500> >>.

B</!\> As in Befunge, code and data share the same playfield, the
character returned can be either an instruction B<or> raw data. No
guarantee is made that the return value is printable.

=item my $str = $storage->rectangle( $pos, $size );

Return a string containing the data/code in the rectangle defined by
the supplied vectors.

=back

=head2 Miscellaneous methods

=over 4

=item my $href = $storage->labels_lookup;

Parse the storage to find sequences such as C<;:(\w[^\s;])[^;]*;>
and return a hash reference whose keys are the labels and the values
an anonymous array with four values: a vector describing the absolute
position of the character just after the trailing C<;>, and a
vector describing the velocity that leads to this label.

This method will only look in the four cardinal directions, and does
wrap basically like befunge93 (however, this should not be a problem
since we're only using cardinal directions)

This allow to define some labels in the source code, to be used by
C<Inline::Befunge> (and maybe some exstensions).

=begin pod_coverage

=item LBV - alias for Language::Befunge::Vector

=end pod_coverage

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
