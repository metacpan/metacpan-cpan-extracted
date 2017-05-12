package EO;

use strict;
use warnings;

use EO::Error;
use Data::UUID;
use EO::Attributes;
use EO::NotAttributes;
use Class::Accessor::Chained;
use Data::Structure::Util qw( get_blessed );
use Storable;

use base qw( Class::Accessor::Chained );

our $VERSION = 0.96;
our $AUTOLOAD;

exception EO::Error::New;
exception EO::Error::Method;
exception EO::Error::Method::Private  extends => 'EO::Error::Method';
exception EO::Error::Method::NotFound extends => 'EO::Error::Method';
exception EO::Error::Method::Abstract extends => 'EO::Error::Method';
exception EO::Error::InvalidParameters;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless $class->primitive(), $class;
    my $text = "Couldn't create object of class '$class'";
    throw EO::Error::New text => $text unless $self->init( @_ );
    if (!$self->{ _eo_init_success }) {
      require Carp;
      my $class = ref($self);
      Carp::cluck("init not passed up the call chain");
    }
    return $self;
}

sub init {
  my $self = shift;
  $self->{ _eo_init_success } = 1;
}

sub generate_oid {
  Data::UUID->new()->create_str();
}

sub primitive : Private {
  return { _eo_init_success => 0 };
}

sub set_oid : Private {
  my $self = shift;
  if (@_) {
    $self->{ oid } = shift;
    return $self;
  }
}

sub oid {
  my $self = shift;
  if (@_) {
    throw EO::Error::InvalidParameters text => "Can't set read-only valid oid";
  }
  ## generate oids lazily
  if (!$self->{ oid }) {
    $self->set_oid( $self->generate_oid() );
  }
  return $self->{ oid };
}

sub AUTOLOAD {
  my $self = shift;
  my $class = ref($self) ? ref($self) : $self;
  my $meth = substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);
  my $text = "Can't locate object method \"$meth\" via package '$class'";
  local($Error::Depth) = $Error::Depth + 1;
  throw EO::Error::Method::NotFound text => $text;
}

sub clone {
  my $self = shift;
  my $clone = Storable::dclone( $self );
  my $objs  = get_blessed( $clone );
  ## ensure we regenerate the oids.
  foreach my $object (@$objs) {
    if ($object->isa('EO')) {
      $object->set_oid( $object->generate_oid() );
    }
  }
  $clone;
}

sub as_string {
  my $self = shift;
  my $class = ref($self);
  return "I am an '$class' object";
}

sub DESTROY { 1; }

1;

__END__

=head1 NAME

EO - A generic base class

=head1 SYNOPSIS

    package Some::Package
    use EO;

    use base qw(EO);

    sub init {
      my $self = shift;

      if ($self->SUPER::init( @_ ) {
        # .. perform initilisation
        return 1;
      }

      return 0;
    }

=head1 DESCRIPTION

This is a base class for the EO module tree.  EO is designed to be a well
tested, solid, simple, and long living base class that other modules can
rely on.  EO inherits from Class::Accessor::Chained, and anything that
inherits from it can easily create its get/set methods.  For more information
see the documentation from Class::Accessor::Chained.

=head1 CONSTRUCTOR

=over 4

=item new()

The constructor takes no arguments and will call the init method.  The
programmer should ensure that the init method in turn calls its
SUPER::init method.  If the EO init method is not called then a warning
will be issued to the effect.  Furthermore the init method should return
true to the constructor.  Your init method should probably look something
like this:

  sub init {
    my $self = shift;
    if ($self->SUPER::init( @_ )) {
      # ... perform initialisation ...
      return 1;
    }
    return 0;
  }

This will ensure that the initialisation occurs all the way up the
parent-class chain.

=back

=head1 METHODS

=over 4

=item oid()

Returns the object id of this object.  Object id's are UUIDs as created
by the Data::UUID module.

=item generate_oid()

Returns a new object id.

=item clone()

The clone method is creates a copy of the object and returns it.  This
is the only method that should be used for cloning in order to refrain
from preserving id's.  The clone method guarantees that all objects
contained within an object that respond true to ->isa('EO') will have
their id's regenerated.

=item as_string()

Provides stringification.  Note -- this is not currently overloaded, but
probably should be considered.

=back

=head1 ATTRIBUTES

=over 4

=item Abstract

The Abstract attribute can be assigned to any method.  When it is assigned
it will cause any attempt to call that method to throw an
EO::Error::Method::Abstract exception. This will happen at runtime.

=item Private

The Private attribute can be assigned to any method.  Any attempt to call this
method from outside the package it is defined in will cause an
EO::Error::Method::Private exception to be thrown.
This will happen at runtime.

=back

=head1 EXCEPTIONS

=over 4

=item EO::Error::New;

This exception is thrown whenever the constructor fails to successfully
initialise an object.  This usually occurs when the init() method does
not return a true value.

=item EO::Error::Method::NotFound

This exception is thrown whenever a message sent to an object cannot
be successfully sent.

=item EO::Error::Method::Abstract

This exception is thrown whenever there is a method call on a method
marked with the Abstract attribute.

=item EO::Error::Method::Private

This exception is thrown whenever there is a method call from outside
the defining package on a method marked with the Private attribute.

=item EO::Error::InvalidParameters

This exception is throw whenever the a message is sent to an object
with incorrect parameters.

=head1 AUTHOR

Arthur Bergman <abergman@fotango.com>
James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2004 Fotango Ltd. All Rights Reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Data::UUID(3)

=cut



