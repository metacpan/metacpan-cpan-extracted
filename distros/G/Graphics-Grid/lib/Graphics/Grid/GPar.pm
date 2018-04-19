package Graphics::Grid::GPar;

# ABSTRACT: Graphical parameters used in Graphics::Grid

use Graphics::Grid::Class;
use MooseX::HasDefaults::RO;

our $VERSION = '0.0001'; # VERSION

use List::AllUtils;
use Graphics::Color::RGB;
use Types::Standard qw(Num Enum ArrayRef Str Value Int);
use Type::Utils qw(declare_coercion);
use namespace::autoclean;

use Graphics::Grid::Types qw(:all);

my $LineMitre   = Num->where( sub { $_ >= 1 } );
my $ZeroToOne   = Num->where( sub { $_ >= 0 and $_ <= 1 } );
my $NonNegative = Num->where( sub { $_ >= 0 } );

# color properties
has [qw(col fill)] => (
    isa => (
        ( ArrayRef [Color] )->plus_coercions( Color, sub { [$_] } )
          ->plus_coercions( Str, sub { [ Color->coerce($_) ] } )
    ),
    coerce => 1,
);
has alpha => (
    isa     => ( ArrayRef [$ZeroToOne] )->plus_coercions(ArrayRefFromValue),
    coerce  => 1,
    default => sub { [1] },
);

# line properties
has lty => (
    isa => ( ArrayRef [LineType] )->plus_coercions(ArrayRefFromValue),
    coerce => 1
);
has lwd => (
    isa => ( ArrayRef [$NonNegative] )->plus_coercions(ArrayRefFromValue),
    coerce => 1
);
has lex => (
    isa     => ( ArrayRef [$NonNegative] )->plus_coercions(ArrayRefFromValue),
    coerce  => 1,
    default => sub { [1] },
);
has lineend => (
    isa => ( ArrayRef [LineEnd] )->plus_coercions(ArrayRefFromValue),
    coerce => 1
);
has linejoin => (
    isa => ( ArrayRef [LineJoin] )->plus_coercions(ArrayRefFromValue),
    coerce => 1
);
has linemitre => (
    isa => ( ArrayRef [$LineMitre] )->plus_coercions(ArrayRefFromValue),
    coerce => 1
);

# text properties
has fontsize => (
    isa => ( ArrayRef [$NonNegative] )->plus_coercions(ArrayRefFromValue),
    coerce => 1
);
has fontfamily => (
    isa => ( ArrayRef [Str] )->plus_coercions(ArrayRefFromValue),
    coerce => 1
);
has fontface => (
    isa => ( ArrayRef [FontFace] )->plus_coercions(ArrayRefFromValue),
    coerce => 1
);
has lineheight => (
    isa    => (ArrayRef)->plus_coercions(ArrayRefFromValue),
    coerce => 1
);

# other properties
has cex => (
    isa     => ( ArrayRef [$NonNegative] )->plus_coercions(ArrayRefFromValue),
    coerce  => 1,
    default => sub { [1] },
);

classmethod names() {
    my @names = qw(col fill alpha
      lty lwd lex lineend linejoin linemitre
      fontsize fontfamily fontface lineheight cex
    );
    return \@names;
}

method _has_param($name) {
    my $val = $self->$name;
    return ( defined $val and @{$val} > 0 );
}

for my $name ( @{ __PACKAGE__->names } ) {
    no strict 'refs';    ## no critic
    *{ "has_" . $name } = sub { $_[0]->_has_param($name); }
}


method at($idx) {
    my %params = map {
        my $val =
            $self->_has_param($_)
          ? $self->$_->[ $idx % scalar( @{ $self->$_ } ) ]
          : undef;
        defined $val ? ( $_ => $val ) : ();
    } @{ $self->names };
    return Graphics::Grid::GPar->new(%params);
}


method merge($another_gpar) {
    my %cumulative_names = map { $_ => 1 } qw(alpha lex cex);

    my %params = map {
        my $key = $_;
        my $val;
        if ( exists( $cumulative_names{$key} ) ) {
            my @self_val    = @{ $self->$key };
            my @another_val = @{ $another_gpar->$key };
            $val = [
                List::AllUtils::pairmap { $a * $b }
                map { $_ // 1 } List::AllUtils::zip( @self_val, @another_val )
            ];
        }
        else {
            $val =
                $self->_has_param($key)         ? $self->$key
              : $another_gpar->_has_param($key) ? $another_gpar->$key
              :                                   undef;
        }
        defined $val ? ( $key => $val ) : ();
    } @{ $self->names };

    return ref($self)->new(%params);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::GPar - Graphical parameters used in Graphics::Grid

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::GPar;
    my $gp1 = Graphics::Grid::GPar->new(col => "red", lwd => 2);

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $gp2 = gpar(col => ["blue", "red"], lty => "solid", fontsize => 16));

=head1 DESCRIPTION

This class represents the set of graphical parameter settings used in
Graphics::Grid.

All grid viewports and graphical objects have an attribute called "gp", which
is an object of this Graphics::Grid::GPar class. When a viewport is pushed
onto the viewport stack and when a graphical object is drawn, the graphical
parameters are enforced in such a way that a Graphics::Grid::GPar object,
which is merged from the "gp" attribute of the graphical object and the
current viewport, would have effect on the graphical output.

The default parameter settings are defined by the ROOT viewport, which takes
its settings from the graphics device. These defaults may differ between
devices.

Valid parameter names are:

=over 4

=item *

col

Colour for lines and borders. Stored values are objects of Graphics::Color::RGB.

=item *

fill

Colour for filling rectangles, polygons, etc. Like C<col>, stored values are
objects of Graphics::Color::RGB.

=item *

alpha

Alpha channel for transparency. During drawing the alpha setting is combined
with the alpha channel for individual colours, like C<col> and C<fill>, by
multiplying.

This parameter is cumulative. If a viewport is pushed with a C<alpha> of
0.5 then another viewport is pushed with a C<alpha> of 0.5, the effective
alpha is 0.25.

=item *

lty

Line type. Allowed values are C<"blank">, C<"solid">, C<"dashed">,
C<"dotted">, C<"dotdash">, C<"longdash">, C<"twodash">.

=item *

lwd

Line width.

=item *

lex

Multiplier applied to line width. The effective line width is C<lwd*lex>.

This parameter is cumulative like C<alpha> mentioned above.

=item *

lineend

Line end style. Allowed values are C<"round">, C<"butt">, C<"square">.

=item * 

linejoin

Line join style. Allowed values are C<"round>, C<"mitre">, C<"bevel">.

=item *

linemitre

Line mitre limit (number >= 1).

=item *

fontsize

The size of text (in points).

=item *

fontfamily

The font family (as a string).

=item *

fontface

The font face. Allowed values are C<"plain">, C<"bold">, C<"italic">,
C<"oblique">, and C<"bold_italic">.

=item *

lineheight

The height of a line as a multiple of the size of text

=item *

cex

Multiplier applied to fontsize. The effective size of text is C<fontsize*cex>.
The size of a line is C<fontsize*cex*lineheight>.

This parameter is cumulative like C<alpha> mentioned above.

=back

All parameter values in object of this class are stored in arrayrefs, so
they can be multiple values that represents settings for multiple components
of a graphical object. The constructor of the class is designed in such a way
that for each parameter you can specify either a single value or an arrayref
of values. See below CONSTRUCTOR section for details.

Also note that dependending on the device driver implementation, some of the
parameters may not be effective. For example, C<lineheight> is not effective
with Graphics::Grid::Driver::Cairo.

=head1 METHODS

=head2 at($idx)

This method returns an object of the same Graphics::Grid::GPar class.
The returned object has at most one value for each of the parameters. 

    my $gp1 = Graphics::Grid::GPar->new(lwd => [2,3,4], lty => "solid");

    # below is same as Graphics::Grid::GPar->new(lwd => 3, lty => "solid");
    my $gp2 = $gp1->at(1);

C<$idx> is applied like wrap-indexing. So below is same as above.

    my $gp3 = $gp1->at(4);

=head2 merge($another_gp)

This method merges two gp objects and returns a merged new object.

    my $gp_merged = $gp1->merge($gp2);

The merge is done is this way:

For a non-cumulative parameter, it would try to get value from the first
object (let's say $gp1), and fallbacks to the second object ($gp2). If both
the parameter is not defined in any of $gp1 and $gp2, the merged object
would not have this parameter either. For example, 

    my $gp1 = Graphics::Grid::GPar->new(col => 'red');
    my $gp2 = Graphics::Grid::GPar->new(col => 'green', fill => 'blue');

    # the result of $gp1->merge($gp2) would be same as
    Graphics::Grid::GPar->new(col => 'red', fill => 'blue');

For a cumulative parameter, the values of $gp1 and $gp2 are multiplied. If
the arrayrefs in $gp1 and $gp2 are not of same length, the shorter one
would be padded with 1 when multiplying. That is,

    my $gp1 = Graphics::Grid::GPar->new(lex => [1, 2, 3]);
    my $gp2 = Graphics::Grid::GPar->new(lex => [1, 2]);

    # the result of $gp1->merge($gp2) would be same as
    Graphics::Grid::GPar->new(lex => [1, 4, 3]);

=head1 CONSTRUCTOR

All parameters for the constructor can be either a single value or an arrayref. 

    # below two are same
    Graphics::Grid::GPar->new(lwd => 2);
    Graphics::Grid::GPar->new(lwd => [2]);

    # via the arrayref form you can specify multiple values for a parameter
    Graphics::Grid::GPar->new(lwd => [2,3,4]);

C<col> and C<fill> also accepts string of color name or hex form.

    # below ones are same
    Graphics::Grid::GPar->new(col => "black");
    Graphics::Grid::GPar->new(col => "#000000");
    Graphics::Grid::GPar->new(
            col => Graphics::Color::RGB->new(red => 0, green => 0, blue => 0));
    Graphics::Grid::GPar->new(col => ["black"]);
    Graphics::Grid::GPar->new(col => ["#000000"]);
    Graphics::Grid::GPar->new(
            col => [ Graphics::Color::RGB->new(red => 0, green => 0, blue => 0) ]);

Different parameters do not have to be of same arreyref length. In fact the
parameters, when they are used in drawing, are wrap-indexed. That is, no
matter a parameter is initialized by a single value or an array ref of
multiple values, a device driver may use a parameter value as if
it is an circular array indexed like C<$real_idx = $given_idx % $size_of_arrayref>.

    # below two are same
    Graphics::Grid::GPar->new(lwd => [2,3,4], lty => "solid");
    Graphics::Grid::GPar->new(lwd => [2,3,4], lty => ["solid", "solid", "solid"]);

    # and they could be equivalent to
    Graphics::Grid::GPar->new(lwd => [2,3,4,2], lty => [("solid") x 4]);
    Graphics::Grid::GPar->new(lwd => [2,3,4,2,3], lty => [("solid") x 5]);
    Graphics::Grid::GPar->new(lwd => [2,3,4,2,3,4], lty => [("solid") x 6]);
    ...

=head1 SEE ALSO

L<Graphics::Grid>

L<Graphics::Grid::Functions>

L<Graphics::Grid::Driver>

L<Graphics::Color::RGB>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
