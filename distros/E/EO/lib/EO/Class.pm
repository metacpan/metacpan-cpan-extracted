package EO::Class;

use strict;
use warnings;

use EO;
use EO::Error;
use EO::Array;
use EO::Method;

use Scalar::Util qw( blessed );

our @ISA = qw( EO );
our $VERSION = 0.96;

exception EO::Error::InvalidState;
exception EO::Error::ClassNotFound;

##
## construct with an object as a parameter
##
sub new_with_object {
  my $class = shift;
  my $obj   = shift;
  if (!$obj || !blessed( $obj )) {
    throw EO::Error::InvalidParameters text => 'no object provided';
  }
  $class->new_with_classname( ref($obj) );
}

##
## construct with a classname as a parameter
##
sub new_with_classname {
  my $class = shift;
  my $obj   = shift;
  if (!$obj || ref($obj)) {
    throw EO::Error::InvalidParameters text => 'no classname provided';
  }
  my $self = $class->new();
  $self->name( $obj );
  return $self;
}


##
## gets/sets the name of the class
##
sub name {
  my $self = shift;
  if (@_) {
    $self->{ classname } = shift;
    return $self;
  }
  return $self->{ classname };
}

##
## adds a method to a class
##
sub add_method {
  my $self   = shift;
  my $method = shift;
  if (!$method) {
    throw EO::Error::InvalidParameters text => "must provide a EO::Method object as an argument";
  }
  if (!$method->name) {
    throw EO::Error::InvalidState text => 'Method object has no name value set';
  }
  if (!$method->reference) {
    throw EO::Error::InvalidState text => 'Method object has no reference value set';
  }
  my $class  = $self->name;
  {
    no strict 'refs';
    *{$class . '::' . $method->name} = $method->reference;
  }
}

##
## gets a method from a class
##
sub get_method {
  my $self = shift;
  my $name = shift;
  if (!$name) {
    throw EO::Error::InvalidParameters text => "no methodname provided";
  }
  if (!$self->name) {
    throw EO::Error::InvalidState text => "class has no name()";
  }
  my $symbol;
  {
    no strict 'refs';
    $symbol = *{$self->name .'::'.$name};
  }
  my $method = EO::Method->new();
  my $ref    = $self->name->can($symbol);
  if ($ref) {
    return EO::Method->new()
                     ->name( $name )
		     ->reference( $ref );
  }
  throw EO::Error::Method::NotFound text => "cannot find method $symbol";
}

##
## returns a list of methods
##
sub methods {
  my $self = shift;
  if (!$self->name) {
    throw EO::Error::InvalidState text => "class has no name()";
  }
  my $glob;
  {
    no strict 'refs';
    $glob = *{$self->name .'::'};
  }
  my @syms = keys %{$glob};
  my $methods = EO::Array->new();
  foreach my $symbol (@syms) {
    next unless $symbol;
    my $method;
    eval {
      $method = $self->get_method( $symbol );
    };
    if (!$@) {
      $methods->push( $method );
    }
  }
  if (wantarray) {
    return $methods->iterator;
  } else {
    return $methods;
  }
}

##
## returns the path to the class as an EO::File object
##
sub path {
  my $self = shift;
  if (!$self->name) {
    throw EO::Error::InvalidState text => "class has no name()";
  }
  my $path = $INC{$self->_classToFile};
  if ($path) {
    my $pathclass = ref($self)->new_with_classname( 'EO::File' );
    eval {
      $pathclass->load();
    };
    if (!$@) {
      EO::File->new( path => $INC{$self->_classToFile} );
    } else {
      EO::File::Stub->new( $path );
    }
  } else {
    my $name = $self->name;
    throw EO::Error::InvalidState text => "class $name has not yet been loaded";
  }
}

##
## returns true if the the class can delegate
##
sub can_delegate {
  my $self = shift;
  if (!$self->name) {
    throw EO::Error::InvalidState text => "class has no name()";
  }
  $self->name->can('delegate');
}

##
## returns the parent classes of the class
##
sub parents {
  my $self = shift;
  if (!$self->name) {
    throw EO::Error::InvalidState text => "class has no name()";
  }
  my $list = EO::Array->new();
  {
    no strict 'refs';
    $list->push( map { EO::Class->new_with_classname( $_ ) } @{$self->name . '::ISA'} );
  }
  if (wantarray) {
    return $list->iterator;
  } else {
    return $list;
  }
}

##
## adds a parent class
##
sub add_parent {
  my $self  = shift;
  {
    no strict 'refs';
    push @{ $self->name . '::ISA' },
      map { (ref( $_ )) ? $_->name : $_ }
	grep { defined }
	  @_;
  }
  return $self;
}

##
## removes a parent class
##
sub del_parent {
  my $self = shift;
  my %PARENTHASH = ();
  {
    no strict 'refs';
    %PARENTHASH = map { ($_ => 1) } @{ $self->name . '::ISA' };
  }
  foreach my $parent (@_) {
    delete $PARENTHASH{ $parent };
  }
  {
    no strict 'refs';
    @{ $self->name . '::ISA' } = keys %PARENTHASH;
  }
  return $self;
}

##
## returns true if the class has been loaded
##
sub loaded {
  my $self = shift;
  my $path;
  !!$INC{ $self->_classToFile };
}

##
## loads a class
##
sub load {
  my $self = shift;
  eval {
    require $self->_classToFile;
  };
  if ($@) {
    throw EO::Error::ClassNotFound text => $@;
  }
  return 1;
}

##
## _classToFile is an internal method used to turn
##  class names into files that may be represented on
##  the disk.  The number of times I have written this
##  in the past I cannot remember...
##
sub _classToFile {
  my $self = shift;
  my $name = $self->name;
  $name =~ s/::/\//g;
  $name .= '.pm';
}

##
##
## stub package to handle situations when EO::File is not installed
##
##
package EO::File::Stub;

use strict;
our @ISA = qw( EO );

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->{ pathname } = shift;
    return 1;
  }
}

sub as_string {
  my $self = shift;
  return $self->{ pathname };
}

1;
__END__

=head1 NAME

EO::Class - introspection class for Perl.

=head1 SYNOPSIS

  use EO::Class

  my $class  = EO::Class->new();
  $class     = EO::Class->new_with_classname( 'Some::Class' );
  $class     = EO::Class->new_with_object( $foo );

  $classname = $class->name;

  $methods   = $class->methods;
  @methods  = $class->methods;

  if ($class->loaded) {
    $path = $class->path
  } else {
    $class->load();
    $path = $class->path;
  }

  $parent_classes = $class->parents;

  $class->add_method(
                     EO::Method->new()
                               ->name('foo')
                               ->reference( sub {} )
                    );

=head1 DESCRIPTION

EO::Class provides reflection capabilities to Perl and specifically
the EO:: tree of modules.

=head1 INHERITANCE

EO::Class inherits from the EO class, and therefore has a constructor
and an initializer

=head1 EXCEPTIONS

EO::Class throws the following exceptions:

=over 4

=item EO::Error::InvalidState

If something that EO::Class relies on is not in a complete state
to be relied on then EO::Class will throw this exception.

=item EO::Error::InvalidParameters

If the parameters passed to methods declared in EO::Class are not
complete then EO::Class throws an InvalidParameters exception.

=item EO::Error::ClassNotFound

If when trying to C<load> a class the class cannot be found.

=back

=head1 CONSTRUCTOR

In addition to the new() constructor provided by EO, EO::Class
provides two additional constructors:

=over 4

=item new_with_object( OBJECT )

Constructs an EO::Class object with the name parameter set to
the the class that OBJECT is an instance of.

=item new_with_classname( CLASS )

Constructs an EO::Class object with the name parameter set to
the class that the string CLASS specifies.

=head1 METHODS

=over 4

=item name()

gets the classname.

=item get_method( STRING )

gets a method named STRING from the class.  It returns an
EO::Method object, or in the case that it doesn't exist,
throws an EO::Error::Method::NotFound object.

=item add_method( EO::Method )

adds a method to the class.  The method is specified by an
EO::Method object.

=item methods()

returns a EO::Array of EO::Method objects.  In list context it
will return a Perl array.

=item path()

if the class is loaded the path method returns an EO::File object,
otherwise an exception is thrown.  If EO::File is not installed then
a stub object is created that provides only the method as_string().
Essentially you are guaranteed to be able to call as_string() on
whatever path() returns.  However, it is recommended that you
install EO::File after installing EO::Class.

=item can_delegate()

if the class delegates using EO::delegate this returns true.

=item parents()

returns an EO::Array object of EO::Class objects that represents
the immediate parents of this class.  If parents() is called in list
context then it returns a Perl array of the modules parent classes,
represented as EO::Class objects.

=item add_parent( LIST )

adds a parent class.  This change is system wide throughout the course of
this runtime.  It will go away when the program terminates.

=item del_parent( LIST )

removes a parent class.  This change is system wide throughout the course of
this runtime.  It will go away when the parent terminates.

=item loaded()

returns true if the class is loaded

=item load()

loads the class into memory

=back

=head1 SEE ALSO

EO::Array, EO::Method, EO::File

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved

=cut

