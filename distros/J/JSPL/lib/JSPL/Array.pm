package JSPL::Array;

use strict;
use warnings;
use JSPL::Object;
use Scalar::Util (); # Don't pollute namespace

our @ISA = qw(JSPL::Object);

use overload
    '@{}' => sub { $_[0]->__content->tie($_[0]->__context, 1); },
    fallback => 1;

sub STORE {
    my ($self,$index,$val) = @_;
    Scalar::Util::looks_like_number($index)
	? $self->__content->set_elem($self->__context, $index, $val)
	: $self->SUPER::STORE($index, $val);
}

sub FETCH {
    my ($self, $index) = @_;
    Scalar::Util::looks_like_number($index) 
	? $self->__content->get_elem($self->__context, $index)
	: $self->SUPER::FETCH($index);
}

sub FETCHSIZE {
    my $self = shift;
    $self->__content->length($self->__context);
}
*length = \&FETCHSIZE;

*SHIFT = \&shift;  # sub SHIFT { $_[0]->shift; }
*POP = \&pop;
*PUSH = \&push;
*UNSHIFT = \&unshift;

*AUTOLOAD = \&JSPL::Object::AUTOLOAD; # Need in 5.8

1;
__END__

=head1 NAME

JSPL::Array - Reference to a JavaScript Array

=head1 DESCRIPTION

Arrays in JavaScript are actually C<Array>-objects. When returned to Perl side,
they are encapsulated in this class and, by default, tied to make them usable
as a normal Perl array-references.

    ...
    my $arr = $ctx->eval(q|['foo', 'bar', 4]|);
    print $arr->[1];     # 'bar'
    print scalar @$arr;  # 3
    print shift @$arr;   # 'foo'
    print ref $arr;      # 'ARRAY'

    my $obj = tied @$arr;
    print ref $obj;      # 'JSPL::Array'

=head1 INTERFACE

When a JavaScript array, i.e an instance of Array, enters perl space the object
is wrapped I<by reference> as a instance of JSPL::Array.

For transparency, and if the C<AutoTie> context option is TRUE, they will be
C<tied> to a perl ARRAY and instead of the JSPL::Array object, the
array-reference is returned, so the regular perl ARRAY operations and functions
will see a normal ARRAY.

All those ARRAYs are I<alive>, that is, they refer to the original javascript
array, .so if you modify them on one side, you are modifying both sides.

    ...
    my $arr = $ctx->eval(q{
        var Arr = ['foo', 'bar', 'baz'];
        Arr;
    });

    $arr->[1] = 'bor';
    pop @$arr;

    print $ctx->eval('Arr[1]');      # 'bor'
    print $ctx->eval('Arr.length');  # 2

    $ctx->eval(q{  Arr.push('fob') });
    print $arr->[2];                 # 'fob'

If you need the underlaying JSPL::Array object, it can be obtained using
Perl's C<tied> operator.

  my $jsarray = tied @$arr;

In javascript all arrays are objects, so this class inherits all
JSPL::Object's features.

=head2 INSTANCE METHODS

=over 4

=item length

Returns the length of the array.

=item shift

=item pop

=item push

=item unshift

=item sort

=item reverse

All performs the standard javascript array methods of the same name.

=back

=cut
