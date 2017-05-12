#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Language::Befunge::Storage::Generic::Vec;
# ABSTRACT: a generic N-dimensional LaheySpace
$Language::Befunge::Storage::Generic::Vec::VERSION = '5.000';
no warnings 'portable'; # "Bit vector size > 32 non-portable" warnings on x64
use Carp;
use Language::Befunge::Vector;
use Language::Befunge::IP;
use base qw{ Language::Befunge::Storage };
use Config;

my $cell_size_in_bytes = $Config{ivsize};
my $cell_size_in_bits  = $cell_size_in_bytes * 8;
# -- CONSTRUCTOR


# try to load speed-up LBSGVXS
eval 'use Language::Befunge::Storage::Generic::Vec::XS';
if ( defined $Language::Befunge::Storage::Generic::Vec::XS::VERSION ) {
    my $xsversion = $Language::Befunge::Vector::XS::VERSION;
    my @subs = qw[
        get_value _get_value set_value _set_value _offset __offset _is_xs expand _expand
    ];
    foreach my $sub ( @subs ) {
        no strict 'refs';
        no warnings 'redefine';
        my $lbsgvxs_sub = "Language::Befunge::Storage::Generic::Vec::XS::$sub";
        *$sub = \&$lbsgvxs_sub;
    }
}


#
# new( dimensions )
#
# Creates a new Lahey Space.
#
sub new {
    my $package = shift;
    my $dimensions = shift;
    my %args = @_;
    my $usage = "Usage: $package->new(\$dimensions, Wrapping => \$wrapping)";
    croak $usage unless defined $dimensions;
    croak $usage unless $dimensions > 0;
    croak $usage unless exists $args{Wrapping};
    my $self  = {
        nd  => $dimensions,
        wrapping => $args{Wrapping},
    };
    bless $self, $package;
    $self->clear();
    return $self;
}


# -- PUBLIC METHODS

#
# clear(  )
#
# Clear the torus.
#
sub clear {
    my $self = shift;
    $$self{min} = Language::Befunge::Vector->new_zeroes($$self{nd});
    $$self{max} = Language::Befunge::Vector->new_zeroes($$self{nd});
    $$self{torus} = chr(0) x $cell_size_in_bytes;
    $self->set_value($$self{min}, 32);
}


#
# expand( v )
#
# Expand the torus to include the provided point.
#
sub expand {
    my ($self, $point) = @_;
    my ($old_min, $old_max) = ($$self{min}, $$self{max});
    # if we have nothing to do, skip out early.
    return if $point->bounds_check($$self{min}, $$self{max});

    $point = $point->copy();
    my $nd = $$self{nd};

    my ($new_min, $new_max) = ($old_min->copy, $old_max->copy);
    foreach my $d (0..$nd-1) {
        $new_min->set_component($d, $point->get_component($d))
            if $new_min->get_component($d) > $point->get_component($d);
        $new_max->set_component($d, $point->get_component($d))
            if $new_max->get_component($d) < $point->get_component($d);
    }
    my $old_size = $old_max - $old_min;
    my $new_size = $new_max - $new_min;

    # figure out the new storage size
    my $storage_size = $self->_offset($new_max, $new_min, $new_max) + 1;

    # figure out what a space looks like on this architecture.
    # Note: vec() is always big-endian, but the XS module is host-endian.
    # So we have to use an indirect approach.
    my $old_value = $self->get_value($self->min);
    $self->set_value($self->min, 32);
    my $new_value = vec($$self{torus}, 0, $cell_size_in_bits);
    $self->set_value($self->min, $old_value);
    # allocate new storage
    my $new_torus = " " x $cell_size_in_bytes;
    vec($new_torus, 0, $cell_size_in_bits) = $new_value;
    $new_torus x= $storage_size;
    for(my $v = $new_min->copy; defined($v); $v = $v->rasterize($new_min, $new_max)) {
        if($v->bounds_check($old_min, $old_max)) {
            my $length     = $old_max->get_component(0) - $v->get_component(0);
            my $old_offset = $self->_offset($v);
            my $new_offset = $self->_offset($v, $new_min, $new_max);
            vec(   $new_torus   , $new_offset, $cell_size_in_bits)
             = vec($$self{torus}, $old_offset, $cell_size_in_bits);
        }
    }
    $$self{min} = $new_min;
    $$self{max} = $new_max;
    $$self{torus} = $new_torus;
}


#
# my $val = get_value( vector )
#
# Return the number stored in the torus at the specified location. If
# the value hasn't yet been set, it defaults to the ordinal value of a
# space (ie, #32).
#
# B</!\> As in Funge, code and data share the same playfield, the
# number returned can be either an instruction B<or> a data (or even
# both... Eh, that's Funge! :o) ).
#
sub get_value {
    my ($self, $v) = @_;
    my $val = 32;

    if ($v->bounds_check($$self{min}, $$self{max})) {
        my $off = $self->_offset($v);
        $val = vec($$self{torus}, $off, $cell_size_in_bits);
    }
    return $self->_u32_to_s32($val);
}


#
# set_value( vector, value )
#
# Write the supplied value in the torus at the specified location.
#
# B</!\> As in Funge, code and data share the same playfield, the
# number stored can be either an instruction B<or> a data (or even
# both... Eh, that's Funge! :o) ).
#
sub set_value {
    my ($self, $v, $val) = @_;

    # Ensure we can set the value.
    $self->expand($v);
    my $off = $self->_offset($v);
    vec($$self{torus}, $off, $cell_size_in_bits) = $self->_s32_to_u32($val);
}


# -- PRIVATE METHODS

#
# _offset(v [, min, max])
#
# Return the offset (within the torus bitstring) of the vector.  If min and max
# are provided, return the offset within a hypothetical torus which has those
# dimensions.
#
sub _offset {
    my ($self, $v, $min, $max) = @_;
    my $nd = $$self{nd};
    my $off_by_1 = Language::Befunge::Vector->new(map { 1 } (1..$nd));
    $min = $$self{min} unless defined $min;
    $max = $$self{max} unless defined $max;
    my $tsize = $max + $off_by_1 - $min;
    my $toff  = $v - $min;
    my $rv = 0;
    my $levsize = 1;
    foreach my $d (0..$nd-1) {
        $rv += $toff->get_component($d) * $levsize;
        $levsize *= $tsize->get_component($d);
    }
    return $rv;
}


sub _s32_to_u32 {
    my ($self, $value) = @_;
    $value = 0xffffffff + ($value+1)
        if $value < 0;
    return $value;
}

sub _u32_to_s32 {
    my ($self, $value) = @_;
    $value = -2147483648 + ($value & 0x7fffffff)
        if($value & 0x80000000);
    return $value;
}

sub _copy {
    my $self = shift;
    my $new = {
        nd       => $$self{nd},
        min      => $$self{min}->copy,
        max      => $$self{max}->copy,
        torus    => $$self{torus},
        wrapping => $$self{wrapping},
    };
    return bless($new, ref($self));
}

sub _is_xs { 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Storage::Generic::Vec - a generic N-dimensional LaheySpace

=head1 VERSION

version 5.000

=head1 SYNOPSIS

    # create a 3-dimensional LaheySpace.
    my $torus = Language::Befunge::Storage::Generic::Vec->new(3);
    $torus->clear();
    $torus->store(<<"EOF");
    12345
    67890
    \fabcde
    fghij
    EOF

Note you usually don't need to use this module directly.
B<Language::Befunge::Interpreter> can optionally use it.  If you are
considering using it, you should really install
L<Language::Befunge::Storage::Generic::Vec::XS> too, as this module is
dreadfully slow without it.  If you cannot install that, you should
use L<Language::Befunge::Storage::Generic::AoA> instead, it will perform
better.

=head1 DESCRIPTION

This module implements a traditional Lahey space.

=head1 CONSTRUCTOR

=head2 new( dimensions )

Creates a new Lahey Space.

=head1 PUBLIC METHODS

=head2 clear(  )

Clear the torus.

=head2 expand( v )

Expand the torus to include the provided point.

=head2 get_value( vector )

Return the number stored in the torus at the specified location. If
the value hasn't yet been set, it defaults to the ordinal value of a
space (ie, #32).

B</!\> As in Funge, code and data share the same playfield, the
number returned can be either an instruction B<or> a data (or even
both... Eh, that's Funge! :o) ).

=head2 set_value( vector, value )

Write the supplied value in the torus at the specified location.

B</!\> As in Funge, code and data share the same playfield, the
number stored can be either an instruction B<or> a data (or even
both... Eh, that's Funge! :o) ).

=head1 EXTERNAL METHODS

Several methods are inherited from the Language::Befunge::Storage base
class.  These methods are:

    store
    store_binary
    get_char
    get_dims
    rectangle
    min
    max
    labels_lookup
    _labels_try

Please see the documentation of that module for more information.

=head1 BUGS

None known.  Please inform me if you find one.

=head1 SEE ALSO

L<Language::Befunge::Storage::Generic::Vec::XS>, L<Language::Befunge::Storage>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
