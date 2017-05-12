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

package Language::Befunge::Storage::Generic::AoA;
# ABSTRACT: a generic N-dimensional LaheySpace
$Language::Befunge::Storage::Generic::AoA::VERSION = '5.000';
use Carp;
use Language::Befunge::Vector;
use Language::Befunge::IP;
use base 'Language::Befunge::Storage';

# -- CONSTRUCTOR


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
    $$self{torus} = [32];
    $$self{torus} = [$$self{torus}] for(1..$$self{nd});
}


#
# expand( vector )
#
# Expand the torus to include the provided point.
#
sub expand {
    my ($self, $v) = @_;
    my $nd = $$self{nd};
    my ($min, $max) = ($$self{min}, $$self{max});

    # if we have nothing to do, skip out early.
    return 0 if $v->bounds_check($min,$max);

    sub _expand_helper {
        my ($d, $v, $torus, $min, $max) = @_;
        my $oldmin = $min->get_component($d); # left end of old array
        my $oldmax = $max->get_component($d); # right end of old array
        my $doff = 0; # prepend this many elements
        $doff = $oldmin - $v->get_component($d) if $v->get_component($d) < $oldmin;
        my $newmin = $oldmin; # left end of new array
        my $newmax = $oldmax; # right end of new array
        $newmin = $v->get_component($d) if $v->get_component($d) < $newmin;
        $newmax = $v->get_component($d) if $v->get_component($d) > $newmax;
        my $append  = $v->get_component($d) - $max->get_component($d);
        $append = 0 if $append < 0; # append this many elements
        my $wholerow = 0;
        # if a higher-level dimension has been expanded where we are, we
        # have to create a new row out of whole cloth.
        for(my $i = $v->get_dims()-1; $i > $d; $i--) {
            $wholerow = 1 if $v->get_component($i) < $min->get_component($i);
            $wholerow = 1 if $v->get_component($i) > $max->get_component($i);
        }
        my @newrow;
        my $o = $v->get_component($d);
        if($d > 0) {
            # handle the nodes we have to create from whole cloth
            for(my $i = 0; $i < $doff; $i++) {
                $v->set_component($d,$i+$newmin);
                push(@newrow,_expand_helper($d-1,$v,undef,$min,$max));
            }
            # handle the nodes we're expanding from existing data
            for(my $i = 0; $i <= ($oldmax-$oldmin); $i++) {
                $v->set_component($d,$i+$oldmin);
                push(@newrow,_expand_helper($d-1,$v,$$torus[$i],$min,$max));
            }
            # handle more nodes we're creating from whole cloth
            for(my $i = $oldmax + 1; $i < $newmax + 1; $i++) {
                $v->set_component($d,$i);
                push(@newrow,_expand_helper($d-1,$v,undef,$min,$max));
            }
        } else {
            for(my $i = $newmin; $i <= $newmax; $i++) {
                if(!$wholerow && ($i >= ($newmin+$doff) && (($i-($newmin+$doff)) <= ($oldmax-$oldmin)))) {
                    # newmin = -3
                    # oldmin = -1
                    #   doff = 2
                    # lhs offset -3-2-1 0 1 2 3 4 5 6 7 8
                    # data        . . a b c d e f g h i j
                    # array index . . 0 1 2 3 4 5 6 7 8 9
                    my $newdata = $$torus[$i-$oldmin];
                    push(@newrow,$newdata);
                } else {
                    push(@newrow,32);
                }
            }
        }
        $v->set_component($d,$o);
        return \@newrow;
    }
    $$self{torus} = _expand_helper($nd - 1, $v, $$self{torus}, $min, $max);
    for(my $d = $$self{nd} - 1; $d > -1; $d--) {
        my $n = $v->get_component($d);
        my $min = $$self{min}->get_component($d);
        my $max = $$self{max}->get_component($d);
        $$self{min}->set_component($d,$n) if $n < $min;
        $$self{max}->set_component($d,$n) if $n > $max;
    }
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
    my $val;

    if ($v->bounds_check($$self{min}, $$self{max})) {
        # for each dimension, go one level deeper into the array.
        $val = $$self{torus};
        for(my $d = $$self{nd} - 1; $d > -1; $d--) {
            $val = $$val[$v->get_component($d) - $$self{min}->get_component($d)];
        }
    }
    return $val if defined $val;
    return 32;  # Default to space.
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
    # for each dimension, go one level deeper into the array.
    my $line = $$self{torus};
    for(my $d = $$self{nd} - 1; ($d > 0); $d--) {
        my $i = $v->get_component($d) - $$self{min}->get_component($d);
        $line = $$line[$i];
    }
    $$line[$v->get_component(0) - $$self{min}->get_component(0)] = $val;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Storage::Generic::AoA - a generic N-dimensional LaheySpace

=head1 VERSION

version 5.000

=head1 SYNOPSIS

    # create a 3-dimensional LaheySpace.
    my $torus = Language::Befunge::Storage::Generic::AoA->new(3);
    $torus->clear();
    $torus->store(<<"EOF");
    12345
    67890
    \fabcde
    fghij
    EOF

Note you usually don't need to use this module directly.
B<Language::Befunge::Interpreter> uses it internally, for non-2-dimensional
storage.  For 2-dimensional storage, B<Language::Befunge::Storage::2D> is used
instead, because it is more efficient.

=head1 DESCRIPTION

This module implements an N-dimensional storage space, as an array of arrays.

=head1 CONSTRUCTOR

=head2 new( dimensions )

Creates a new Lahey Space.

=head1 PUBLIC METHODS

=head2 clear(  )

Clear the torus.

=head2 expand( vector )

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

L<Language::Befunge::Storage>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
