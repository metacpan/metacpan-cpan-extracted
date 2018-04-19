package Graphics::Grid::Types;

# ABSTRACT: Custom types and coercions used by Graphics::Grid

use 5.014;
use warnings;

our $VERSION = '0.0001'; # VERSION

use Ref::Util qw(is_plain_arrayref);
use Type::Library -base, -declare => qw(
  UnitName Unit UnitArithmetic UnitLike
  GPar
  PlottingCharacter
  LineType LineEnd LineJoin
  FontFace
  Color
  Justification Clip
);

use Type::Utils -all;
use Types::Standard -types;


class_type Unit, { class => 'Graphics::Grid::Unit' };
coerce Unit,
  from Value,    via { 'Graphics::Grid::Unit'->new($_) },
  from ArrayRef, via { 'Graphics::Grid::Unit'->new($_) };

class_type UnitArithmetic, { class => 'Graphics::Grid::UnitArithmetic' };

declare UnitLike, as ConsumerOf["Graphics::Grid::UnitLike"];
coerce UnitLike,
  from Value,    via { 'Graphics::Grid::Unit'->new($_) },
  from ArrayRef, via { 'Graphics::Grid::Unit'->new($_) };

class_type GPar, { class => 'Graphics::Grid::GPar' };
coerce GPar, from HashRef, via { 'Graphics::Grid::GPar'->new($_) };

class_type Color, { class => 'Graphics::Color::RGB' };
coerce Color, from Str, via {
    if ( $_ =~ /^\#[[:xdigit:]]+$/ ) {
        'Graphics::Color::RGB'->from_hex_string($_);
    }
    else {
        'Graphics::Color::RGB'->from_color_library($_);
    }
};

declare Justification, as ArrayRef [Num], where { @$_ == 2 };
coerce Justification, from Str, via {
    state $mapping;
    unless ($mapping) {
        $mapping = {
            left   => [ 0,   0.5 ],
            top    => [ 0.5, 1 ],
            right  => [ 1,   0.5 ],
            bottom => [ 0.5, 0 ],
            center => [ 0.5, 0.5 ],
            centre => [ 0.5, 0.5 ],
        };
        $mapping->{bottom_left}  = $mapping->{left_bottom}  = [ 0, 0 ];
        $mapping->{top_left}     = $mapping->{left_top}     = [ 0, 1 ];
        $mapping->{bottom_right} = $mapping->{right_bottom} = [ 1, 0 ];
        $mapping->{top_right}    = $mapping->{right_top}    = [ 1, 1 ];
    }

    unless ( exists $mapping->{$_} ) {
        die "invalid justification";
    }
    return $mapping->{$_};
};

# For unit with multiple names, like "inches" and "in", we directly support
#  only one of its names, and handle other names via coercion.
declare UnitName, as Enum [qw(npc cm inches mm points picas char native)];
coerce UnitName, from Str, via {
    state $mapping;
    unless ($mapping) {
        $mapping = {
            "in"          => "inches",
            "pt"          => "points",
            "pc"          => "picas",
            "centimetre"  => "cm",
            "centimeter"  => "cm",
            "centimetres" => "cm",
            "centimeters" => "cm",
            "millimiter"  => "mm",
            "millimeter"  => "mm",
            "millimiters" => "mm",
            "millimeters" => "mm",
        };
    }
    return ( $mapping->{$_} // $_ );
};

declare PlottingCharacter, as (Int | Str), where { length($_) > 0 };

declare LineType,
  as Enum [qw(blank solid dashed dotted dotdash longdash twodash)];
declare LineEnd,  as Enum [qw(round butt square)];
declare LineJoin, as Enum [qw(round mitre bevel)];

declare FontFace, as Enum [qw(plain bold italic oblique bold_italic)];
coerce FontFace, from Str, via {
    sub { $_ =~ s/\./_/gr; }
};

declare Clip, as Enum [qw(on off inherit)];

declare_coercion "ArrayRefFromAny", to_type ArrayRef, from Any, via { is_plain_arrayref($_) ? $_ : [$_] };
declare_coercion "ArrayRefFromValue", to_type ArrayRef, from Value,
  via { [$_] };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::Types - Custom types and coercions used by Graphics::Grid

=head1 VERSION

version 0.0001

=head1 SEE ALSO

L<Graphics::Grid>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
