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

package Language::Befunge::Storage;
# ABSTRACT: a generic Storage base class for Language::Befunge
$Language::Befunge::Storage::VERSION = '5.000';
use Carp;
use Language::Befunge::Vector;
use Language::Befunge::IP;
use aliased 'Language::Befunge::Vector' => 'LBV';


# -- PUBLIC METHODS


#
# store( code, [vector] )
#
# Store the given code at the specified vector.  If the coordinates
# are omitted, then the code is stored at the origin (0, 0).
#
# Return the size of the code inserted, as a vector.
#
# The code is a string, representing a block of Funge code.  Rows are
# separated by newlines.  Planes are separated by form feeds.  A complete list of
# separators follows:
#
#     Axis    Delimiter
#     X       (none)
#     Y       \n
#     Z       \f
#     4       \0
#
# The new-line and form-feed delimiters are in the Funge98 spec.  However, there
# is no standardized separator for dimensions above Z.  Currently, dimensions 4
# and above use \0, \0\0, \0\0\0, etc.  These are dangerously ambiguous, but are
# the only way I can think of to retain reverse compatibility.  Suggestions for
# better delimiters are welcome.  (Using XML would be really ugly, I'd prefer not
# to.)
#
sub store {
    my ($self, $code, $base) = @_;
    my $nd = $$self{nd};
    $base = Language::Befunge::Vector->new_zeroes($$self{nd}) unless defined $base;

    # support for any eol convention
    $code =~ s/\r\n/\n/g;
    $code =~ s/\r/\n/g;

    # The torus is a tree of arrays of numbers.
    # The tree is N levels deep, where N is the number of dimensions.
    # Each number is the ordinal value of the character held in this cell.

    my @separators = ("", "\n", "\f");
    push(@separators, "\0"x($_-3)) for (4..$nd); # , "\0", "\0\0", "\0\0\0"...
    my $separators = join("", @separators);
    my %separators = ( map { $separators[$_] => $_ } (1..@separators-1));
    my @sizes = map { 0 } (1..$nd);
    my @newvalues;
    my $this = $base->copy;
    while(length($code)) {
        my $value = substr($code, 0, 1, '');
        if(index($separators, $value) > -1) {
            last unless length $code;
            my $d = $separators{$value};
            my $new = $this->get_component($d) + 1;
            $this->set_component($d, $new);
            $sizes[$d] = $new if $new > $sizes[$d];
            foreach my $i (0..$d-1) {
                my $last = $this->get_component($i);
                $this->set_component($i, $base->get_component($i));
                $sizes[$i] = $last if $last > $sizes[$i];
            }
        } else {
            my $last = $this->get_component(0);
            unless($value eq ' ') {
                push(@newvalues, [$this->copy, ord($value)]);
                $sizes[0] = $last if $last > $sizes[0];
            }
            $this->set_component(0, $last + 1);
        }
    }

    return unless scalar @newvalues;

    # Figure out the rectangle size and the end-coordinate (max).
    my $size = Language::Befunge::Vector->new(map { $_ + 1 } @sizes);
    my $max  = Language::Befunge::Vector->new(@sizes);
    $size -= $base;

    # Enlarge torus to make sure our new values will fit.
    $self->expand( $base );
    $self->expand( $max );

    # Store code.
    foreach my $pair (@newvalues) {
        $self->set_value(@$pair);
    }

    return $size;
}


#
# store_binary( code, [vector] )
#
# Store the given code at the specified coordinates. If the coordinates
# are omitted, then the code is stored at the Origin(0, 0) coordinates.
#
# Return the size of the code inserted, as a vector.
#
# This is binary insertion, that is, EOL and FF sequences are stored in
# Funge-space instead of causing the dimension counters to be reset and
# incremented.  The data is stored all in one row.
#
sub store_binary {
    my ($self, $code, $base) = @_;
    my $nd = $$self{nd};
    $base = Language::Befunge::Vector->new_zeroes($$self{nd})
        unless defined $base;

    # The torus is a tree of arrays of numbers.
    # The tree is N levels deep, where N is the number of dimensions.
    # Each number is the ordinal value of the character held in this cell.

    my @sizes = length($code);
    push(@sizes,1) for(2..$nd);

    # Figure out the min, max, and size
    my $size = Language::Befunge::Vector->new(@sizes);
    my $max  = Language::Befunge::Vector->new(map { $_ - 1 } (@sizes));
    $max += $base;

    # Enlarge torus to make sure our new values will fit.
    $self->expand( $base );
    $self->expand( $max );

    # Store code.
    for(my $v = $base->copy; defined($v); $v = $v->rasterize($base, $max)) {
        my $char = substr($code, 0, 1, "");
        next if $char eq " ";
        $self->set_value($v, ord($char));
    }
    return $size;
}


#
# get_char( vector )
#
# Return the character stored in the torus at the specified location. If
# the value is not between 0 and 255 (inclusive), get_char will return a
# string that looks like "<np-0x4500>".
#
# B</!\> As in Funge, code and data share the same playfield, the
# character returned can be either an instruction B<or> raw data.  No
# guarantee is made that the return value is printable.
#
sub get_char {
    my $self = shift;
    my $v = shift;
    my $ord = $self->get_value($v);
    # reject invalid ascii
    return sprintf("<np-0x%x>",$ord) if ($ord < 0 || $ord > 255);
    return chr($ord);
}


#
# my $str = rectangle( start, size )
#
# Return a string containing the data/code in the specified rectangle.
#
sub rectangle {
    my ($self, $v1, $v2) = @_;
    my $nd = $$self{nd};

    # Fetch the data.
    my $data = "";
    my $min = $v1;
    foreach my $d (0..$nd-1) {
        # each dimension must >= 1, otherwise the rectangle will be empty.
        return "" unless $v2->get_component($d);
        # ... but we need to offset by -1, to calculate $max
        $v2->set_component($d, $v2->get_component($d) - 1);
    }
    my $max = $v1 + $v2;
    # No separator is used for the first dimension, for obvious reasons.
    # Funge98 specifies lf/cr/crlf for a second-dimension separator.
    # Funge98 specifies a form feed for a third-dimension separator.
    # Funge98 doesn't specify what dimensions 4 and above should use.
    # We use increasingly long strings of null bytes.
    # (4d uses 1 null byte, 5d uses 2, 6d uses 3, etc)
    my @separators = "";
    push(@separators,"\n") if $nd > 1;
    push(@separators,"\f") if $nd > 2;
    push(@separators,"\0"x($_-3)) for (4..$nd); # , "\0", "\0\0", "\0\0\0"...
    my $prev = $min->copy;
    for(my $v = $min->copy; defined($v); $v = $v->rasterize($min, $max)) {
        foreach my $d (0..$$self{nd}-1) {
            $data .= $separators[$d]
                if $prev->get_component($d) != $v->get_component($d);
        }
        $prev = $v;
        $data .= $self->get_char($v);
    }
    return $data;
}


# expand( vector )

# Expand the storage range to include the specified point, if necessary.
# This version of expand() is meant for Sparse modules; it only adjusts the min
# and max vectors with no other effect.  Non-sparse modules should supercede
# this method to do something more meaningful.

sub expand {
    my ($self, $v) = @_;
    my $min = $$self{min};
    my $max = $$self{max};
    foreach my $d (0..$$self{nd}-1) {
        $min->set_component($d, $v->get_component($d))
            if $v->get_component($d) < $min->get_component($d);
        $max->set_component($d, $v->get_component($d))
            if $v->get_component($d) > $max->get_component($d);
    }
}


#- misc methods

#
# my %labels = labels_lookup(  )
#
# Parse the Lahey space to find sequences such as C<;:(\w[^\s;])[^;]*;>
# and return a hash reference whose keys are the labels and the values
# an anonymous array with two vectors: a vector describing the absolute
# position of the character B<just after> the trailing C<;>, and a
# vector describing the velocity that lead to this label.
#
# This method will only look in the cardinal directions; west, east,
# north, south, up, down and so forth.
#
# This allow to define some labels in the source code, to be used by
# C<Inline::Befunge> (and maybe some extensions).
#
sub labels_lookup {
    my $self = shift;
    my $labels = {};

    my ($min, $max) = ($$self{min}, $$self{max});
    my $nd = $$self{nd};
    my @directions = ();
    foreach my $dimension (0..$nd-1) {
        # build the array of (non-diagonal) vectors
        my $v1 = Language::Befunge::Vector->new_zeroes($nd);
        my $v2 = $v1->copy;
        $v1->set_component($dimension,-1);
        push(@directions,$v1);
        $v2->set_component($dimension, 1);
        push(@directions,$v2);
    }
    
    R: for(my $this = $min->copy; defined($this); $this = $this->rasterize($min, $max)) {
        V: for my $v (@directions) {
            next R unless $self->get_char($this) eq ";";
            my ($label, $loc) = $self->_labels_try( $this, $v );
            next V unless defined($label);

            # How exciting, we found a label!
            croak "Help! I found two labels '$label' in the funge space"
                if exists $labels->{$label};
            $$labels{$label} = [$loc, $v];
        }
    }

    return $labels;
}


#
# my $dims = get_dims()
#
# Returns the number of dimensions this storage object operates in.
#
sub get_dims {
    my $self = shift;
    return $$self{nd};
}


#
# my $vector = min()
#
# Returns a Vector object, pointing at the beginning of the torus.
# If nothing has been stored to a negative offset, this Vector will
# point at the origin (0,0).
#
sub min {
    my $self = shift;
    return $$self{min}->copy;
}


#
# my $vector = max()
#
# Returns a Vector object, pointing at the end of the torus.
# This is usually the largest position which has been written to.
#
sub max {
    my $self = shift;
    return $$self{max}->copy;
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
    my ($self, $start, $delta) = @_;
    my $comment = "";
    my $wrapping = $$self{wrapping};
    my $ip = Language::Befunge::IP->new($$self{nd});
    my $min = $self->min;
    my $max = $self->max;
    $ip->set_position($start->copy);
    $ip->set_delta($delta);

    # Fetch the whole comment stuff.
    do {
        # Calculate the next cell coordinates.
        my $v = $ip->get_position;
        my $d = $ip->get_delta;

        # now, let's move the ip.
        $v += $d;

        if ( $v->bounds_check($min, $max) ) {
            $ip->set_position( $v );
        } else {
            $wrapping->wrap( $self, $ip );
        }

        $comment .= $self->get_char($ip->get_position());
    } while ( $comment !~ /;.$/ );

    # Check if the comment matches the pattern.
    $comment =~ /^:(\w[^\s;]*)[^;]*;.$/;
    return ($1, $ip->get_position());
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Storage - a generic Storage base class for Language::Befunge

=head1 VERSION

version 5.000

=head1 SYNOPSIS

    my $storage = Language::Befunge::Storage::Generic::AoA->new;
    $storage->clear;
    $storage->store(<<EOF);
    12345
    67890
    EOF

=head1 DESCRIPTION

This class implements a set of basic methods which can be used by all
Storage subclasses.  Subclasses may choose to override any or all of these
methods, for efficiency reasons... these methods are the baseline, generic
counterparts.

These methods will work with any subclass which stores the number of
dimensions within the self hash, as the "nd" key, and the minimum and
maximum vector sizes stored as "min" and "max", respectively.  No
other assumptions about the storage model are made; they just call
expand, get_value and set_value to do their dirty work.

=head1 PUBLIC METHODS

=head2 Storage update

=over 4

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

=item $storage->expand( vector );

Expand the storage range to include the specified point, if necessary.
This is a stub method, to be superceded by subclasses which do something
meaningful here.

It is usually called for new "min" and "max" values, for efficiency reasons:
if we expand the storage ahead of time, we only have to do the expansion
once, rather than expanding it again and again every time a rasterize loop
reaches new ground.

Sparse storage models do not need this; all other storage models should
implement a specific method to resize their data structure.

=back

=head2 Data retrieval

=over 4

=item my $dims = $storage->get_dims;

Return the number of dimensions this storage object operates in.

=item my $vmin = $storage->min;

Return a LBV pointing to the lower bounds of the storage.

=item my $vmax = $storage->max;

Return a LBV pointing to the upper bounds of the storage.

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
