package JIRA::REST::Class::Abstract;
use parent qw( Class::Accessor::Fast JIRA::REST::Class::Mixins );
use strict;
use warnings;
use 5.010;

our $VERSION = '0.10';
our $SOURCE = 'CPAN';
## $SOURCE = 'GitHub';  # COMMENT
# the line above will be commented out by Dist::Zilla

# ABSTRACT: An abstract class for L<JIRA::REST::Class|JIRA::REST::Class> that most of the other objects are based on.

use Carp;
use Data::Dumper::Concise;
use Scalar::Util qw( weaken blessed reftype refaddr);

__PACKAGE__->mk_ro_accessors( qw( data issue lazy_loaded ) );

#pod =internal_method B<init>
#pod
#pod Method to perform post-instantiation initialization of the object. The first
#pod argument must be the factory object which created the object.  Subclasses of
#pod C<JIRA::REST::Class::Abstract> are expected to call
#pod C<< $self->SUPER::init(@_); >> somewhere in their own C<init()>.
#pod
#pod =cut

sub init {
    my $self    = shift;
    my $factory = shift;

    # the first thing we're passed is supposed to be the factory object
    if (   blessed $factory
        && blessed $factory eq 'JIRA::REST::Class::Factory' ) {

        # grab the arguments that the class was called with from the factory
        # and make new factory and class objects with the same aguments so we
        # don't have circular dependency issues

        my $args = $factory->{args};
        $self->factory( $args );
        $self->jira( $args );
    }
    else {
        # if we're not passed a factory, let's complain about it
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        confess 'factory not passed to init!';
    }

    # unload any lazily loaded data
    $self->unload_lazy;

    # init() has to return the object!
    return $self;
}

#pod =internal_method B<unload_lazy>
#pod
#pod I'm using a hash to track which lazily loaded methods have already been
#pod loaded, and this method clears that hash (and the field that got loaded) so
#pod they get loaded again.
#pod
#pod =cut

sub unload_lazy {
    my $self = shift;
    if ( $self->{lazy_loaded} ) {
        foreach my $field ( keys %{ $self->{lazy_loaded} } ) {
            delete $self->{$field};
            delete $self->{lazy_loaded}->{$field};
        }
    }
    else {
        $self->{lazy_loaded} = {};
    }
    return;
}

#pod =internal_method B<populate_scalar_data>
#pod
#pod Code to make instantiating objects from C<< $self->{data} >> easier.  Accepts
#pod three unnamed parameters:
#pod
#pod =over 2
#pod
#pod =item * key in this object's hash which will hold the resulting object
#pod
#pod =item * nickname for object type being created (to be passed to C<make_object()>)
#pod
#pod =item * key under C<< $self->{data} >> that should be passed as the data to C<make_object()>
#pod
#pod =back
#pod
#pod =cut

sub populate_scalar_data {
    my ( $self, $name, $type, $field ) = @_;

    if ( defined $self->data->{$field} ) {
        $self->{$name} = $self->make_object(
            $type,
            {
                data => $self->data->{$field}
            }
        );
    }
    return;
}

#pod =internal_method B<populate_date_data>
#pod
#pod Code to make instantiating DateTime objects from C<< $self->{data} >> easier.
#pod Accepts two unnamed parameters:
#pod
#pod =over 2
#pod
#pod =item * key in this object's hash which will hold the resulting object
#pod
#pod =item * key under C<< $self->{data} >> that should be passed as the data to C<make_date()>
#pod
#pod =back
#pod
#pod =cut

sub populate_date_data {
    my ( $self, $name, $field ) = @_;
    if ( defined $self->data->{$field} ) {
        $self->{$name} = $self->make_date( $self->data->{$field} );
    }
    return;
}

#pod =internal_method B<populate_list_data>
#pod
#pod Code to make instantiating lists of objects from C<< $self->{data} >> easier.
#pod Like L</populate_scalar_data>, it accepts three unnamed parameters:
#pod
#pod =over 2
#pod
#pod =item * key in this object's hash which will hold the resulting list reference
#pod
#pod =item * nickname for object type being created (to be passed to C<make_object()>) as each item in the list
#pod
#pod =item * key under C<< $self->{data} >> that should be interpreted as a list reference, each element of which is passed as the data to C<make_object()>
#pod
#pod =back
#pod
#pod =cut

sub populate_list_data {
    my ( $self, $name, $type, $field ) = @_;
    if ( defined $self->data->{$field} ) {
        $self->{$name} = [  # stop perltidy from pulling
            map {           # these lines together
                $self->make_object( $type, { data => $_ } )
            } @{ $self->data->{$field} }
        ];
    }
    else {
        $self->{$name} = [];  # rather than undefined, return an empty list
    }
    return;
}

#pod =internal_method B<populate_scalar_field>
#pod
#pod Code to make instantiating objects from C<<  $self->{data}->{fields} >> easier.   Accepts
#pod three unnamed parameters:
#pod
#pod =over 2
#pod
#pod =item * key in this object's hash which will hold the resulting object
#pod
#pod =item * nickname for object type being created (to be passed to C<make_object()>)
#pod
#pod =item * key under C<<  $self->{data}->{fields} >> that should be passed as the data to C<make_object()>
#pod
#pod =back
#pod
#pod =cut

sub populate_scalar_field {
    my ( $self, $name, $type, $field ) = @_;
    if ( defined $self->fields->{$field} ) {
        $self->{$name} = $self->make_object(
            $type,
            {
                data => $self->fields->{$field}
            }
        );
    }
    return;
}

#pod =internal_method B<populate_list_field>
#pod
#pod Code to make instantiating lists of objects from C<<  $self->{data}->{fields} >> easier.
#pod Like L</populate_scalar_field>, it accepts three unnamed parameters:
#pod
#pod =over 2
#pod
#pod =item * key in this object's hash which will hold the resulting list reference
#pod
#pod =item * nickname for object type being created (to be passed to C<make_object()>) as each item in the list
#pod
#pod =item * key under C<<  $self->{data}->{fields} >> that should be interpreted as a list reference, each element of which is passed as the data to C<make_object()>
#pod
#pod =back
#pod
#pod =cut

sub populate_list_field {
    my ( $self, $name, $type, $field ) = @_;
    if ( defined $self->fields->{$field} ) {
        $self->{$name} = [  # stop perltidy from pulling
            map {           # these lines together
                $self->make_object( $type, { data => $_ } )
            } @{ $self->fields->{$field} }
        ];
    }
    else {
        $self->{$name} = [];  # rather than undefined, return an empty list
    }
    return;
}

###########################################################################
#
# the code in here is liberally borrowed from
# Class::Accessor, Class::Accessor::Fast, and Class::Accessor::Contextual
#

if ( eval { require Sub::Name } ) {
    Sub::Name->import;
}

#pod =internal_method B<mk_contextual_ro_accessors>
#pod
#pod Because I didn't want to give up
#pod L<Class::Accessor::Fast|Class::Accessor::Fast>, but wanted to be able to
#pod make contextual accessors when it was useful.  Accepts a list of accessors
#pod to make.
#pod
#pod =cut

sub mk_contextual_ro_accessors {
    my ( $class, @fields ) = @_;

    foreach my $field ( @fields ) {
        my $accessor = sub {
            if ( @_ == 1 ) {
                my $ptr = $_[0];
                return $ptr->{$field} unless wantarray;
                return @{ $ptr->{$field} } if ref( $ptr->{$field} ) eq 'ARRAY';
                return %{ $ptr->{$field} } if ref( $ptr->{$field} ) eq 'HASH';
                return $ptr->{$field};
            }
            else {
                my $caller = caller;
                $_[0]->_croak( "'$caller' cannot alter the value of '$field' "
                        . "on objects of class '$class'" );
            }
        };

        $class->make_subroutine( $field, $accessor );
    }

    return $class;
}

#pod =internal_method B<mk_deep_ro_accessor>
#pod
#pod Why do accessors have to be only for the top level of the hash?  Why can't
#pod they be several layers deep?  This method takes a list of keys for the hash
#pod this object is based on and creates a contextual accessor that goes down
#pod deeper than just the first level.
#pod
#pod   # create accessor for $self->{foo}->{bar}->{baz}
#pod   __PACKAGE__->mk_deep_ro_accessor(qw/ foo bar baz /);
#pod
#pod =cut

sub mk_deep_ro_accessor {
    my ( $class, @field ) = @_;

    my $accessor = sub {
        if ( @_ == 1 ) {
            my $ptr = $_[0];
            foreach my $f ( @field ) {
                $ptr = $ptr->{$f};
            }
            return $ptr unless wantarray;
            return @$ptr if ref( $ptr ) eq 'ARRAY';
            return %$ptr if ref( $ptr ) eq 'HASH';
            return $ptr;
        }
        else {
            my $caller = caller;
            $_[0]->_croak( "'$caller' cannot alter the value of '$field[-1]' "
                    . "on objects of class '$class'" );
        }
    };

    $class->make_subroutine( $field[-1], $accessor );

    return $class;
}

#pod =internal_method B<mk_lazy_ro_accessor>
#pod
#pod Takes two parameters: field to make a lazy accessor for, and a subroutine
#pod reference to construct the value of the accessor when it IS loaded.
#pod
#pod This method makes an accessor with the given name that checks to see if the
#pod value for the accessor has been loaded, and, if it hasn't, runs the provided
#pod subroutine to construct the value and stores that value for later use.
#pod Especially good for loading values that are objects populated by REST calls.
#pod
#pod   # code to construct a lazy accessor named 'foo'
#pod   __PACKAGE__->mk_lazy_ro_accessor('foo', sub {
#pod       my $self = shift;
#pod       # make the value for foo, in say, $foo
#pod       return $foo;
#pod   });
#pod
#pod =cut

sub mk_lazy_ro_accessor {
    my ( $class, $field, $constructor ) = @_;

    my $accessor = sub {
        if ( @_ == 1 ) {
            unless ( $_[0]->{lazy_loaded}->{$field} ) {
                $_[0]->{$field} = $constructor->( @_ );
                $_[0]->{lazy_loaded}->{$field} = 1;
            }
            return $_[0]->{$field} unless wantarray;
            return @{ $_[0]->{$field} } if ref( $_[0]->{$field} ) eq 'ARRAY';
            return %{ $_[0]->{$field} } if ref( $_[0]->{$field} ) eq 'HASH';
            return $_[0]->{$field};
        }
        else {
            my $caller = caller;
            $_[0]->_croak( "'$caller' cannot alter the value of '$field' "
                    . "on objects of class '$class'" );
        }
    };

    $class->make_subroutine( $field, $accessor );

    return $class;
}

#pod =internal_method B<mk_data_ro_accessors>
#pod
#pod Makes accessors for keys under C<< $self->{data} >>
#pod
#pod =cut

sub mk_data_ro_accessors {
    my ( $class, @args ) = @_;

    foreach my $field ( @args ) {
        $class->mk_deep_ro_accessor( qw( data ), $field );
    }
    return;
}

#pod =internal_method B<mk_field_ro_accessors>
#pod
#pod Makes accessors for keys under C<< $self->{data}->{fields} >>
#pod
#pod =cut

sub mk_field_ro_accessors {
    my ( $class, @args ) = @_;

    foreach my $field ( @args ) {
        $class->mk_deep_ro_accessor( qw( data fields ), $field );
    }
    return;
}

#pod =internal_method B<make_subroutine>
#pod
#pod Takes a subroutine name and a subroutine reference, and blesses the
#pod subroutine into the class used to call this method.  Can be called with
#pod either a class name or a blessed object reference.
#pod
#pod =cut

{
    # we're going some magic here, so we turn off our self-restrictions
    no strict 'refs'; ## no critic (ProhibitNoStrict)

    sub make_subroutine {
        my ( $proto, $name, $sub ) = @_;
        my ( $class ) = ref $proto || $proto;

        my $fullname = "${class}::$name";
        unless ( defined &{$fullname} ) {
            subname( $fullname, $sub ) if defined &subname;
            *{$fullname} = $sub;
        }
        return;
    }

}  # end of ref no-stricture zone

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Packy Anderson Alexey Melezhik jira JRC

=head1 NAME

JIRA::REST::Class::Abstract - An abstract class for L<JIRA::REST::Class|JIRA::REST::Class> that most of the other objects are based on.

=head1 VERSION

version 0.10

=head1 METHODS

=head2 B<name_for_user>

When passed a scalar that could be a
L<JIRA::REST::Class::User|JIRA::REST::Class::User> object, returns the name
of the user if it is a C<JIRA::REST::Class::User>
object, or the unmodified scalar if it is not.

=head2 B<key_for_issue>

When passed a scalar that could be a
L<JIRA::REST::Class::Issue|JIRA::REST::Class::Issue> object, returns the key
of the issue if it is a C<JIRA::REST::Class::Issue>
object, or the unmodified scalar if it is not.

=head2 B<find_link_name_and_direction>

When passed two scalars, one that could be a
L<JIRA::REST::Class::Issue::LinkType|JIRA::REST::Class::Issue::LinkType>
object and another that is a direction (inward/outward), returns the name of
the link type and direction if it is a C<JIRA::REST::Class::Issue::LinkType>
object, or attempts to determine the link type and direction from the
provided scalars.

=head2 B<dump>

Returns a stringified representation of the object's data generated somewhat
by L<Data::Dumper::Concise|Data::Dumper::Concise>, but not descending into
any objects that might be part of that data.  If it finds objects in the
data, it will attempt to represent them in some abbreviated fashion which
may not display all the data in the object.  For instance, if the object has
a C<JIRA::REST::Class::Issue> object in it for an issue with the key
C<'JRC-1'>, the object would be represented as the string C<<
'JIRA::REST::Class::Issue->key(JRC-1)' >>.  The goal is to provide a gist of
what the contents of the object are without exhaustively dumping EVERYTHING.
I use it a lot for figuring out what's in the results I'm getting back from
the JIRA API.

=head1 INTERNAL METHODS

=head2 B<init>

Method to perform post-instantiation initialization of the object. The first
argument must be the factory object which created the object.  Subclasses of
C<JIRA::REST::Class::Abstract> are expected to call
C<< $self->SUPER::init(@_); >> somewhere in their own C<init()>.

=head2 B<unload_lazy>

I'm using a hash to track which lazily loaded methods have already been
loaded, and this method clears that hash (and the field that got loaded) so
they get loaded again.

=head2 B<populate_scalar_data>

Code to make instantiating objects from C<< $self->{data} >> easier.  Accepts
three unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting object

=item * nickname for object type being created (to be passed to C<make_object()>)

=item * key under C<< $self->{data} >> that should be passed as the data to C<make_object()>

=back

=head2 B<populate_date_data>

Code to make instantiating DateTime objects from C<< $self->{data} >> easier.
Accepts two unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting object

=item * key under C<< $self->{data} >> that should be passed as the data to C<make_date()>

=back

=head2 B<populate_list_data>

Code to make instantiating lists of objects from C<< $self->{data} >> easier.
Like L</populate_scalar_data>, it accepts three unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting list reference

=item * nickname for object type being created (to be passed to C<make_object()>) as each item in the list

=item * key under C<< $self->{data} >> that should be interpreted as a list reference, each element of which is passed as the data to C<make_object()>

=back

=head2 B<populate_scalar_field>

Code to make instantiating objects from C<<  $self->{data}->{fields} >> easier.   Accepts
three unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting object

=item * nickname for object type being created (to be passed to C<make_object()>)

=item * key under C<<  $self->{data}->{fields} >> that should be passed as the data to C<make_object()>

=back

=head2 B<populate_list_field>

Code to make instantiating lists of objects from C<<  $self->{data}->{fields} >> easier.
Like L</populate_scalar_field>, it accepts three unnamed parameters:

=over 2

=item * key in this object's hash which will hold the resulting list reference

=item * nickname for object type being created (to be passed to C<make_object()>) as each item in the list

=item * key under C<<  $self->{data}->{fields} >> that should be interpreted as a list reference, each element of which is passed as the data to C<make_object()>

=back

=head2 B<mk_contextual_ro_accessors>

Because I didn't want to give up
L<Class::Accessor::Fast|Class::Accessor::Fast>, but wanted to be able to
make contextual accessors when it was useful.  Accepts a list of accessors
to make.

=head2 B<mk_deep_ro_accessor>

Why do accessors have to be only for the top level of the hash?  Why can't
they be several layers deep?  This method takes a list of keys for the hash
this object is based on and creates a contextual accessor that goes down
deeper than just the first level.

  # create accessor for $self->{foo}->{bar}->{baz}
  __PACKAGE__->mk_deep_ro_accessor(qw/ foo bar baz /);

=head2 B<mk_lazy_ro_accessor>

Takes two parameters: field to make a lazy accessor for, and a subroutine
reference to construct the value of the accessor when it IS loaded.

This method makes an accessor with the given name that checks to see if the
value for the accessor has been loaded, and, if it hasn't, runs the provided
subroutine to construct the value and stores that value for later use.
Especially good for loading values that are objects populated by REST calls.

  # code to construct a lazy accessor named 'foo'
  __PACKAGE__->mk_lazy_ro_accessor('foo', sub {
      my $self = shift;
      # make the value for foo, in say, $foo
      return $foo;
  });

=head2 B<mk_data_ro_accessors>

Makes accessors for keys under C<< $self->{data} >>

=head2 B<mk_field_ro_accessors>

Makes accessors for keys under C<< $self->{data}->{fields} >>

=head2 B<make_subroutine>

Takes a subroutine name and a subroutine reference, and blesses the
subroutine into the class used to call this method.  Can be called with
either a class name or a blessed object reference.

=head2 B<jira>

Returns a L<JIRA::REST::Class|JIRA::REST::Class> object with credentials for the last JIRA user.

=head2 B<factory>

An accessor for the L<JIRA::REST::Class::Factory|JIRA::REST::Class::Factory>.

=head2 B<JIRA_REST>

An accessor that returns the L<JIRA::REST|JIRA::REST> object being used.

=head2 B<REST_CLIENT>

An accessor that returns the L<REST::Client|REST::Client> object inside the L<JIRA::REST|JIRA::REST> object being used.

=head2 B<JSON>

An accessor that returns the L<JSON|JSON> object inside the L<JIRA::REST|JIRA::REST> object being used.

=head2 B<make_object>

A pass-through method that calls L<JIRA::REST::Class::Factory::make_object()|JIRA::REST::Class::Factory/make_object>.

=head2 B<make_date>

A pass-through method that calls L<JIRA::REST::Class::Factory::make_date()|JIRA::REST::Class::Factory/make_date>.

=head2 B<class_for>

A pass-through method that calls L<JIRA::REST::Class::Factory::get_factory_class()|JIRA::REST::Class::Factory/get_factory_class>.

=head2 B<obj_isa>

When passed a scalar that I<could> be an object and a class string,
returns whether the scalar is, in fact, an object of that class.
Looks up the actual class using C<class_for()>, which calls
L<JIRA::REST::Class::Factory::get_factory_class()|JIRA::REST::Class::Factory/get_factory_class>.

=head2 B<cosmetic_copy> I<THING>

A utility function to produce a "cosmetic" copy of a thing: it clones
the data structure, but if anything in the structure (other than the
structure itself) is a blessed object, it replaces it with a
stringification of that object that probably doesn't contain all the
data in the object.  For instance, if the object has a
C<JIRA::REST::Class::Issue> object in it for an issue with the key
C<'JRC-1'>, the object would be represented as the string
C<< 'JIRA::REST::Class::Issue->key(JRC-1)' >>.  The goal is to provide a
gist of what the contents of the object are without exhaustively dumping
EVERYTHING.

=head1 RELATED CLASSES

=over 2

=item * L<JIRA::REST::Class|JIRA::REST::Class>

=item * L<JIRA::REST::Class::Factory|JIRA::REST::Class::Factory>

=item * L<JIRA::REST::Class::Mixins|JIRA::REST::Class::Mixins>

=back

=head1 AUTHOR

Packy Anderson <packy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Packy Anderson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
