package Graphics::Grid::UnitArithmetic;

# ABSTRACT: Expression created from Graphics::Grid::Unit objects

use Graphics::Grid::Class;

our $VERSION = '0.0001'; # VERSION

use Scalar::Util qw(looks_like_number);
use Type::Params ();
use Types::Standard qw(Str ArrayRef Any Num);
use namespace::autoclean;

use Graphics::Grid::Util qw(points_to_cm);
use Graphics::Grid::Types qw(:all);

extends 'Forest::Tree';

use overload
  "+"        => 'plus',
  "-"        => 'minus',
  "*"        => 'multiply',
  "fallback" => 1;


has '+node' => (
    isa => (
        ( ArrayRef [Num] )->plus_coercions( Num, sub { [$_] } ) |
          Str->where( sub { $_ =~ /^[\*\+\-]$/ } ) | Unit
    ),
    coerce => 1,
);


has '+children' => (
    isa => ArrayRef [
        UnitArithmetic->plus_coercions( Any,
            sub {
                if ( $_->$_isa('Graphics::Grid::UnitArithmetic') ) {
                    return $_;
                }
                my $node = $_;
                unless ( $_->$_isa('Graphics::Grid::Unit')
                    or Ref::Util::is_arrayref($node) )
                {
                    $node = [$node];
                }
                return Graphics::Grid::UnitArithmetic->new( node => $node );
            }
        )
    ],
    coerce => 1,
);

with qw(
  Graphics::Grid::UnitLike
);


method at($idx) {
    if ( $self->is_unit ) {
        return __PACKAGE__->new( node => $self->node->at($idx) );
    }
    elsif ( $self->is_number ) {
        return __PACKAGE__->new(
            node => [ $self->node->[ $idx % $self->elems ] ] );
    }
    else {
        return __PACKAGE__->new(
            node     => $self->node,
            children => [ map { $_->at($idx) } @{ $self->children } ]
        );
    }
}


method elems() {
    if ( $self->is_unit ) {
        return $self->node->elems;
    }
    elsif ( $self->is_number ) {
        return scalar( @{ $self->node } );
    }
    else {
        return List::AllUtils::max( map { $_->elems } @{ $self->children } );
    }
};


method is_unit() {
    return $self->node->$_isa('Graphics::Grid::Unit');
}


method is_number() {
    return Ref::Util::is_arrayref( $self->node );
}


method is_arithmetic() {
    return !( $self->is_unit() or $self->is_number() );
}


method stringify() {
    if ( $self->is_unit ) {
        return $self->node->stringify;
    }
    elsif ( $self->is_number ) {
        return join( ', ', @{ $self->node } );
    }
    else {
        return join(
            ', ',
            map {
                my $arg0 = $self->children->[0]->at($_);
                my $arg1 = $self->children->[1]->at($_);
                my $format;
                if ( $self->node eq '*' ) {
                    if ( $arg0->is_arithmetic ) {
                        $format = "(%s)%s%s";
                    }
                    elsif ( $arg1->is_arithmetic ) {
                        $format = "%s%s(%s)";
                    }
                }
                $format //= "%s%s%s";
                sprintf( $format,
                    $arg0->stringify, $self->node, $arg1->stringify );
            } ( 0 .. $self->elems - 1 )
        );
    }
}

method _make_operation( $op, $other, $swap = undef ) {
    return __PACKAGE__->new(
        node     => $op,
        children => ( $swap ? [ $other, $self ] : [ $self, $other ] )
    );
}

method plus( UnitLike $other, $swap = undef ) {
    return $self->_make_operation( '+', $other, $swap );
}

method minus( UnitLike $other, $swap = undef ) {
    return $self->_make_operation( '-', $other, $swap );
}

method multiply( ( ArrayRef [Num] | Num ) $other, $swap = undef ) {
    return $self->_make_operation( '*', $other, $swap );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Grid::UnitArithmetic - Expression created from Graphics::Grid::Unit objects

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use Graphics::Grid::UnitArithmetic;
    use Graphics::Grid::Unit;

    my $ua1 = Graphics::Grid::UnitArithmetic->new(
        node     => '+',
        children => [
            Graphics::Grid::Unit->new( [ 1, 2, 3 ], "cm" ),
            Graphics::Grid::Unit->new(0.5),
        ],
    );
    my $ua2 = Graphics::Grid::UnitArithmetic->new(
        Graphics::Grid::Unit->new(0.1, "npc")
    );
    my $ua3 = $ua1 - $ua2;
    my $ua4 = $ua1 * 2;

    # or use the function interface
    use Graphics::Grid::Functions qw(:all);
    my $ua = unit(@params) * 2;

=head1 DESCRIPTION

You would mostly never directly use this class. See
L<Graphics::Grid::Unit> for unit arithmetic on unit objects.

This class Graphics::Grid::UnitArithmetic represents arithmetic on
Graphics::Grid::Unit objects. It provides a way to create a unit-like
value that combines both relative and absolute values.

Supported operators are C<+>, C<->, and C<*>. A plus or minus
operation requires both its binary operands are consumers of 
Graphics::Grid::UnitLike. The multiply operation requires one of
its operands is consumer of Graphics::Grid::UnitLike, the other
a number or array ref of numbers.

=head1 ATTRIBUTES

=head2 node

It can be one of the followings,

=over 4

=item * 

A number or an array ref of numbers. If a single number is given it
will be coerced to an array ref that contains the number. This is
used for operands of multiplications.

=item * 

One of C<"+">, C<"-">, C<"*">. In this case the C<children> attr
should contain the operands.

=item *

A Graphics::Grid::Unit object. This is used for operands of plus
and minus.

=back

=head2 children

When the object represents an arithmetic operation, this C<children>
attribute has the operands.

=head1 METHODS

=head2 at($idx)

This method returns an object of the same Graphics::Grid::UnitArithmetic class.
The returned object represents the data at given index, and has at only one
value at each node. 

    # $ua1 has 3 elems: 1cm+0.5npc, 2cm+0.5npc, 3cm+0.5npc
    my $ua1 = Graphics::Grid::UnitArithmetic->new(
        node     => '+',
        children => [
            Graphics::Grid::Unit->new( [ 1, 2, 3 ], "cm" ),
            Graphics::Grid::Unit->new(0.5),
        ],
    );

    # $ua2 has only 2cm+0.5npc
    my $ua2 = $u1->at(1);

C<$idx> is applied like wrap-indexing. So below is same as above.

    my $ua3 = $ua1->at(4);

=head2 elems

Return the number of effective elements in the object.

=head2 is_unit

Checks if the object is a Graphics::Grid::Unit.

=head2 is_number

Checks if the object is an array ref of numbers.

=head2 is_arithmetic

Check is the object is an arithmetic operation. It is equivalent
to C<!($obj-E<ge>is_unit() or $obj-E<ge>is_number())>.

=head2 stringify

Stringify the object.

=head1 SEE ALSO

L<Graphics::Grid>

L<Graphics::Grid::UnitLike>

L<Graphics::Grid::Unit>

L<Forest::Tree>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
