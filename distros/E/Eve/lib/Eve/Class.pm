package Eve::Class;

use strict;
use warnings;

use Contextual::Return;

use Eve::Support;

our $AUTOLOAD;

=head1 NAME

B<Eve::Class> - a class that all other library classes use as a
parent.

=head1 SYNOPSIS

    use parent qw(Eve::Class);

    sub init {
        my ($self, %arg_hash) = @_;

        $self->{'_private_property'} = 'Private value';
        $self->{'public_property'} = 'Public value';
        $self->_private_method();
        $self->public_method();

        return;
    }

=head1 DESCRIPTION

B<Eve::Class> is an abstract class whose functionality is used in
derived classes in order to avoid initialization code duplication and
make routine procedures easier.

=head2 Implicit accessors

Another purpose of this class is to provide a mechanism that
simplifies access to object properties.

Every property can be accessed using C<$foo->name> notation. If there
is additional processing required before getting or setting a property
custom getters and setters can be used. They can be defined as methods
by prefixing the property name with 'get_' or 'set_'. In this case
they will be called instead of accessing the property directly.

    package Foo;

    use parent qw(Eve::Class);

    sub init {
        my $self = shift;

        $self->{'name'} = 'some value';

        return;
    }

    sub set_name {
        my ($self, $value) = @_;

        $self->{'name'} = lc($value);
    }

    1;

    # Later ...

    $foo->name = 'Another Value';

=head1 METHODS

=head2 B<new()>

This method is the constructor. It can be called both on the class
and on the object. Calling the constructor on an existing object
will return a new object of the instance's class.

    package Foo;

    use parent qw(Eve::Class);

    1;

    # Later ...

    my $foo1 = Foo->new('Your arguments here');
    my $foo2 = $foo1->new('Your new arguments here');

=head3 Arguments

An arbitrary number of arguments which will be later passed to the
C<init()> method.

=head3 Returns

A new instance of the class that the method is being called on.

=cut

sub new {
    my $class = shift;

    my $self  = {};
    bless($self, (ref($class) or $class));

    # Calling init with the same @_
    $self->init(@_);
    return $self;
}

=head2 B<init()>

This method is called after an object has been instantiated using the C<new()>
method, all parameters that have been passed to the constructor are passed
to this method also.

If you need the object to have certain properties, you need to explicitly
define them as hash keys inside this method.

    package Foo;
    use parent qw(Eve::Class);

    sub init {
        my ($self, %arg_hash) = @_;

        $self->{'_private_property'} = 'Private value';
        $self->{'public_property'} = 'Public value';

        return;
    }

    1;

After that you can access the object's properties in this manner:

    my $foo1 = Foo->new();
    print $foo1->public_property;
    $foo1->public_property = 'Another value';
    $foo1->_private_property = 'Whoops!';

Please note that there is no mechanism to make properties really private or
protected, which means that you can access all properties from outside, no
matter what they are called.

=head3 Arguments

Note that this method should not be called directly. The C<new()> method
must be called instead, and all its arguments will be passed directly to
this method.

=cut

sub init {
    # Init method stub
}

sub _accessor {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($is_set, $name, $value));

    if (not exists $self->{$name}) {
        Eve::Error::Attribute->throw(
            message => "Property $name does not exist");
    }

    my $method = ('_get', '_set')[$is_set].'_'.$name;
    my $result;
    if ($self->can($method)) {
        $result = $self->$method($value);
    } else {
        if ($is_set) {
            $self->{$name} = $value;
        }
        $result = $self->{$name}
    }

    return $result;
}

sub AUTOLOAD : lvalue {
    my $self = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*:://;

    NVALUE {
        Eve::Error::Attribute->throw(
            message => "Method $name does not exist") }
    LVALUE { $self->_accessor(is_set => 1, name => $name, value => $_) }
    RVALUE { $self->_accessor(is_set => 0, name => $name, value => undef) }
}

sub DESTROY {
    return;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=back

=cut

1;
