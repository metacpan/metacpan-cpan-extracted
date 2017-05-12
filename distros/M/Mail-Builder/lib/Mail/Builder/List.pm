# ============================================================================
package Mail::Builder::List;
# ============================================================================

use namespace::autoclean;
use Moose;
use Mail::Builder::TypeConstraints;

use Carp;

our $VERSION = $Mail::Builder::VERSION;

has 'type' => (
    is          => 'ro',
    isa         => 'Mail::Builder::Type::Class',
    required    => 1,
);

has 'list' => (
    is          => 'rw',
    isa         => 'ArrayRef[Object]',
    default     => sub { return [] },
    trigger     => \&_check_list,
    traits      => ['Array'],
    handles     => {
        length      => 'count',
        #all         => 'elements',
    },
);

sub _check_list {
    my ($self,$value) = @_;

    my $type = $self->type;

    foreach my $element (@$value) {
        unless (blessed $element
            && $element->isa($type)) {
            croak("'$value' is not a '$type'");
        }
    }
    return;
}

around 'list' => sub {
    my $orig = shift;
    my $self = shift;

    my $result = $self->$orig(@_);

    return wantarray ? @{$result} : $result;
};

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if (scalar @_ == 1
        && ref($_[0]) eq '') {
        return $class->$orig({ type => $_[0] });
    } else {
        return $class->$orig(@_);
    }
};


__PACKAGE__->meta->make_immutable;

sub _convert_item { ## no critic(RequireArgUnpacking)
    my ($self) = shift;

    croak(qq[Params missing])
        unless scalar @_;

    my $type = $self->type;

    if (blessed($_[0])) {
        croak(qq[Invalid item added to list: Must be of $type])
            unless ($_[0]->isa($type));
        return $_[0];
    } else {
        my $object = $type->new(@_);
        croak(qq[Could not create $type object])
            unless (defined $object
            && blessed $object
            && $object->isa($type));

        return $object;
    }
}

sub convert {
    my ($class,@elements) = @_;

    my $elements_ref = (scalar @elements == 1 && ref $elements[0] eq 'ARRAY') ?
        $elements[0] : \@elements;

    return $class->new(
        type    => ref($elements_ref->[0]),
        list    => $elements_ref,
    );
}

sub join { ## no critic(ProhibitBuiltinHomonyms)
    my ($self,$join_string) = @_;

    return CORE::join $join_string,
        grep { $_ }
        map { $_->serialize }
        $self->list;
}

sub contains {
    my ($self,$compare) = @_;

    return 0
        unless (defined $compare);

    foreach my $item ($self->list) {
        return 1
            if (blessed($compare) && $item == $compare);
        return 1
            if ($item->compare($compare));
    }
    return 0;
}

sub reset { ## no critic(ProhibitBuiltinHomonyms)
    my ($self) = @_;

    $self->list([]);
    return 1;
}

sub push { ## no critic(RequireArgUnpacking,ProhibitBuiltinHomonyms)
    my ($self) = @_;
    return $self->add(@_);
}

sub remove {
    my ($self,$remove) = @_;

    my $list = $self->list;

    # No params: take last param
    unless (defined $remove) {
        return pop @{$list};
    # Element
    } else {
        my $new_list = [];
        my $old_value;
        my $index = 0;
        foreach my $item (@{$list}) {
            if (blessed($remove) && $item == $remove
                || ($remove =~ /^\d+$/ && $index == $remove)
                || $item->compare($remove)) {
                $remove = $item;
            } else {
                CORE::push(@{$new_list},$item);
            }
            $index ++;
        }
        $self->list($new_list);

        # Return old value
        return $remove
            if defined $remove;
    }
    return;
}

sub add { ## no critic(RequireArgUnpacking)
    my ($self) = shift;

    my $item = $self->_convert_item(@_);

    unless ($self->contains($item)) {
        CORE::push(@{$self->list}, $item);
    }

    return $item;
}


sub item {
    my ($self,$index) = @_;

    $index = 0
        unless defined $index
        && $index =~ m/^\d+$/;

    return
        unless ($index =~ m/^\d+$/
        && defined $self->list->[$index]);

    return $self->list->[$index];
}

__PACKAGE__->meta->make_immutable;

1;

=encoding utf8

=head1 NAME

Mail::Builder::List - Helper module for handling various lists

=head1 SYNOPSIS

  use Mail::Builder;
  
  # Create a list that accepts Mail::Builder::Address objects
  my $list = Mail::Builder::List->new('Mail::Builder::Address');
  
  # Add aMail::Builder::Address object
  $list->add($address_object);
  
  # Add an email (Unrecognized values will be passed to the constructor of
  # the type class - Mail::Builder::Address)
  $list->add('sasha.nein@psychonauts.org');
  
  # Add one more email (Unrecognized values will be passed to the constructor of
  # the type class - Mail::Builder::Address)
  $list->add({ email => 'raz.aquato@psychonauts.org', name => 'Razputin'} );
  
  # Remove email from list
  $list->remove('raz.aquato@psychonauts.org');
  
  # Remove first element in list
  $list->remove(1);
  
  # Reset list
  $list->reset;
  
  # Add email
  $list->add('milla.vodello@psychonauts.org','Milla Vodello');
  
  # Serialize email list
  print $list->join(',');

=head1 DESCRIPTION

This is a helper module for handling various lists (e.g. recipient, attachment
lists). The class contains convinient array/list handling functions.

=head1 METHODS

=head2 Constructor

=head3 new

 my $list = Mail::Builder::List->new(Class name);
 OR
 my $list = Mail::Builder::List->new({
     type   => Class name,
     [ list => ArrayRef, ]
 });

This constructor takes the class name of the objects it should hold. It is
only possible to add objects of the given type. It is not possible to change
the assigned type later.

=head3 convert

 my $list = Mail::Builder::List->convert(ArrayRef);

Constructor that converts an array reference into a Mail::Builder::List
object. The list type is defined by the first element of the array.

=head2 Public Methods

=head3 length

Returns the number of items in the list.

=head3 add

 $obj->add(Object);
 OR
 $obj->add(Anything)

Pushes a new item into the list. The methods either accepts an object or
any values. Values will be passed to the C<new> method in the
list type class.

=head3 push

Synonym for L<add>

=head3 remove

 $obj->remove(Object)
 OR
 $obj->remove(Index)
 OR
 $obj->remove(Anything)
 OR
 $obj->remove()

Removes the given element from the list. If no parameter is passed to the
method the last element from the list will be removed instead.

=head3 reset

Removes all elements from the list, leaving an empty list.

=head3 item

 my $list_item = $obj->item(Index)

Returns the list item with the given index.

=head3 join

 my $list = $obj->join(String)

Serializes all items in the list and joins them using the given string.

=head3 contains

 $obj->contains(Object)
 or
 $obj->contains(Anything)

Returns true if the given object is in the list. You can either pass an
object or scalar value. Uses the L<compare> method from the list type class.

=head2 Accessors

=head3 type

Returns the class name which was initially passed to the constructor.

=head3 list

Raw list as list or array reference.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=cut
