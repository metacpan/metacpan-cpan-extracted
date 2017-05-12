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

package Language::Befunge::Storage::Generic::Sparse;
# ABSTRACT: a generic N-dimensional LaheySpace
$Language::Befunge::Storage::Generic::Sparse::VERSION = '5.000';
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
    $$self{torus} = {};
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
    my $str = "$v";
    return 32 unless exists $$self{torus}{$str};
    return $$self{torus}{$str};
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

    # update min/max
    $self->expand($v);
    my $str = "$v";
    $$self{torus}{$str} = $val;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Storage::Generic::Sparse - a generic N-dimensional LaheySpace

=head1 VERSION

version 5.000

=head1 SYNOPSIS

    # create a 3-dimensional LaheySpace.
    my $torus = Language::Befunge::Storage::Generic::Sparse->new(3);
    $torus->clear();
    $torus->store(<<"EOF");
    12345
    67890
    \fabcde
    fghij
    EOF

Note you usually don't need to use this module directly.
B<Language::Befunge::Interpreter> can optionally use it.

=head1 DESCRIPTION

This module implements an N-dimensional storage space, as a sparse hash.  The
values in the hash are keyed by coordinate strings, as created by stringifying
a Vector object.

=head1 CONSTRUCTOR

=head2 new( dimensions )

Creates a new Lahey Space.

=head1 PUBLIC METHODS

=head2 clear(  )

Clear the torus.

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
    expand
    min
    max
    labels_lookup
    _labels_try

Please see the documentation of that module for more information.

=head1 BUGS

None known.  Please inform me if you find one.

=head1 SEE ALSO

<Language::Befunge::Storage>, L<Language::Befunge::Storage::2D::Sparse>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
