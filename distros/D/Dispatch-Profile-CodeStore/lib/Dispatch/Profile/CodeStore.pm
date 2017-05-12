package Dispatch::Profile::CodeStore;
#-------------------------------------------------------------------------------
#   Module  : Dispatch::Profile::CodeStore
#
#   Purpose : Stores coderefs for future calling via an extended dispatch 
#             method
#-------------------------------------------------------------------------------
use Moose;
use Moose::Util::TypeConstraints;
our $VERSION = '0.002';

#-------------------------------------------------------------------------------
#   Object constructor parameters
#-------------------------------------------------------------------------------
has 'class_loader', is => 'ro', required => 0;
has 'profile', is => 'ro', required => 1, default => sub { return {} };

#-------------------------------------------------------------------------------
#   Subroutine : BUILD
#
#   Purpose : Post creation manipulation of object to link desired targets
#             with corresponding code references
#-------------------------------------------------------------------------------
sub BUILD {
   my $self = shift;

   #-------------------------------------------------------------------------------
   #   If the class_loader attribute is set as a Scalar, coerce the Scalar to an
   #   Array to ease load processing
   #-------------------------------------------------------------------------------
   if ( defined $self->{class_loader} ) {
      match_on_type $self->{class_loader} => (
         Str => sub {
            $self->{class_loader} = [ $self->{class_loader} ];
         },
         ArrayRef => sub {
         },
         => sub { die "ERROR: Attribute class_loader is not an acceptable type" }
      );

      #-------------------------------------------------------------------------------
      #   Process array and load class(es) that have been implicitly specified
      #-------------------------------------------------------------------------------
      for my $class ( @{ $self->{class_loader} } ) {

         #-------------------------------------------------------------------------------
         #   Load the class but do not import methods, Perl Critic error ignored
         #   as $class is processed with dynamic expression evaluation
         #-------------------------------------------------------------------------------
         eval "require $class";    ## no critic
         die "ERROR: Could not load class $class - $@" if $@;
      }
   }

   #-------------------------------------------------------------------------------
   #   If the profile type is set as a HashRef, coerce the HashRef to an
   #   Array to ease load processing
   #-------------------------------------------------------------------------------
   if ( defined $self->{profile} ) {

      match_on_type $self->{profile} => (
         HashRef => sub {
            $self->{profile} = [ $self->{profile} ];
         },
         ArrayRef => sub {
         },
         => sub { die "ERROR: Attribute $self->{profile} is not an acceptable type" }
      );

      #-------------------------------------------------------------------------------
      #   Process each profile type's record
      #-------------------------------------------------------------------------------
      my $record_number = 0;
      for my $record ( @{ $self->{profile} } ) {

         #-------------------------------------------------------------------------------
         #   Process array and load class(es) that have specified within a record
         #-------------------------------------------------------------------------------
         if ( defined $record->{class} ) {

            #-------------------------------------------------------------------------------
            #   Check if the class is not already loaded
            #-------------------------------------------------------------------------------
            no strict "refs"; ## no critic
            my $package = $record->{class} . "::";
            if ( ! %{$package} ) {

               #-------------------------------------------------------------------------------
               #   Attempt to load the class but do not import methods, Perl Critic error ignored
               #   as $class is processed with dynamic expression evaluation
               #-------------------------------------------------------------------------------
               eval "require $record->{class}";    ## no critic
               die "ERROR: Could not load class $record->{class} - $@" if $@;
            }
         }

         #-------------------------------------------------------------------------------
         #   If a type was specified with an implicit class, and with the option
         #   to instantiate as an object, verify that the class provides the corresponding
         #   target method and a new method constructor, if it succeeds
         #   instantiate the object if it is not already instantiated and store a
         #   reference to the object within self, use the instantiate_opts arg to create
         #   the object if available
         #-------------------------------------------------------------------------------
         if (  ( defined $record->{class} )
            && ( defined $record->{target} )
            && ( defined $record->{object} ) 
            && ( $record->{class}->can( $record->{target} ) )
            && ( $record->{class}->can('new') ) ) {

            #-------------------------------------------------------------------------------
            #   Instantiate the object if it is not already instantiated
            #-------------------------------------------------------------------------------
            if ( !defined $self->{_objects}{$record_number}{ $record->{class} } ) {

               # Create an args holder
               my %args = ();

               # Use the supplied arguments if available
               %args = %{ $record->{object} };

               # Attempt to instantiate the object, die if there is an issue
               eval { $self->{_objects}{$record_number}{ $record->{class} } = $record->{class}->new(%args); };
               die "ERROR: Could not load instantiate an object using $record->{class}->new - $@" if $@;
            }

            #-------------------------------------------------------------------------------
            #   If the desired object exists
            #-------------------------------------------------------------------------------
            if ( defined $self->{_objects}{$record_number}{ $record->{class} } ) {

               #-------------------------------------------------------------------------------
               #   Verify that the object can action the required method
               #-------------------------------------------------------------------------------
               if ( $self->{_objects}{$record_number}{ $record->{class} }->can( $record->{target} ) ) {

                  #-------------------------------------------------------------------------------
                  #   Utilise closures to provide 'Persistent Private Variables' to the anonymous
                  #   subroutine, as per the 'perlsub' man page
                  #-------------------------------------------------------------------------------
                  {
                     my $private_number = $record_number;
                     my $private_method = $record->{target};
                     my $private_class  = $record->{class};

                     #-------------------------------------------------------------------------------
                     # Use closures with an anonymous sub to provide what is essentially a CODEREF
                     # to an Object method.  It's not possible to directly reference an object method,
                     # instead you need to reference the class method code and provide the object as
                     # the first parameter to the method when called.  This is detailed at
                     # http://www.perlmonks.org/?node_id=62737 ... the closures
                     # approach is detailed by mirod, the method calling with an object is detailed
                     # by davorg - This uses the closures method...
                     #-------------------------------------------------------------------------------
                     my $object_method_sub = sub {

                        #-------------------------------------------------------------------------------
                        #    Call the object with the method, directly pass any supplied parameters
                        #-------------------------------------------------------------------------------
                        $self->{_objects}{$private_number}{$private_class}->$private_method(@_);
                     };

                     #-------------------------------------------------------------------------------
                     #   Push the object_method_sub reference on to the corresponding type list
                     #-------------------------------------------------------------------------------
                     push @{ $self->{"_store"} }, \&{$object_method_sub};
                  }
               }
            }
         }

         #-------------------------------------------------------------------------------
         #   If a target was specified with an implicit class, verify that the
         #   class provides the corresponding target method, if it succeeds
         #   store as a coderef within the object
         #-------------------------------------------------------------------------------
         elsif ( ( defined $record->{class} )
            && ( defined $record->{target} )
            && ( $record->{class}->can( $record->{target} ) ) ) {

            #-------------------------------------------------------------------------------
            #   Push a reference to the target on to the _$type data_set_name store
            #-------------------------------------------------------------------------------
            push @{ $self->{"_store"} }, \&{"$record->{class}\::$record->{target}"};
         }

         #-------------------------------------------------------------------------------
         #   If a target is specified without an implicit class, try and find
         #   the appropriate method
         #-------------------------------------------------------------------------------
         elsif ( ( !defined $record->{class} ) && ( defined $record->{target} ) ) {

            #-------------------------------------------------------------------------------
            #   Try and find the method in the main namespace, i.e. has the module been
            #   loaded with 'use', thus resulting in imports to the main namespace
            #-------------------------------------------------------------------------------
            if ( main->can("$record->{target}") ) {

               #-------------------------------------------------------------------------------
               #   Method was found in main
               #   Push a reference to the handler on to the _handler data_set_name store
               #-------------------------------------------------------------------------------
               push @{ $self->{"_store"} }, \&{"main\::$record->{target}"};
            }

            #-------------------------------------------------------------------------------
            #   If it was not found in the main namespace, search through the list of
            #   modules within class_loader
            #-------------------------------------------------------------------------------
            else {

               my $match_success = 0;

               for my $class ( @{ $self->{class_loader} } ) {
                  if ( $match_success ne 1 ) {
                     if ( $class->can("$record->{target}") ) {

                        #-------------------------------------------------------------------------------
                        #   Push a reference to the target on to the _$type data_set_name store
                        #-------------------------------------------------------------------------------
                        push @{ $self->{"_store"} }, \&{"$class\::$record->{target}"};
                        $match_success = 1;
                     }
                  }
               }

               #-------------------------------------------------------------------------------
               #   If the method was not found, alert
               #-------------------------------------------------------------------------------
               if ( $match_success == 0 ) {
                  die "ERROR:  Did not find $record->{target} in any of the loaded classes";
               }

            }
         }
         $record_number++;
      }
   }
}

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Dispatch::Profile coderef store

__END__

=pod

=encoding UTF-8

=head1 NAME

Dispatch::Profile::CodeStore - Dispatch::Profile coderef store

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This module provides a Moose BUILD constructor that is utilised by the Dispatch::Profile package.  
It is responsible for parsing the supplied profile and storing the associated
target code references.

=head2 BUILD

Moose constructor with the following configurable parameters

=head3 class_loader => 'String'

A string containing a module to load at runtime

  class_loader => 'Data::Dumper'

=head3 class_loader => [ 'String', 'String' ]

Multiple modules can be loaded through an array of strings

  class_loader => [ 'Data::Dumper', 'DBI' ]

=head3 profile => HashRef

Profiles are defined through a HashRef of profile parameters

  profile => { }

=head3 profile => [ HashRef, HashRef ]

Multiple profiles can be defined through an array of hashref
profile parameters

  profile => [ 
     { }, 
     { }, 
  ],

=head2 PROFILE PARAMETERS

The following parameters can be used within the profile hashref

=head3 target => 'String'

Specifies the target method for use with the profile

  profile => {
     target => 'target_method',
  }

=head3 class => 'String'

Specifies the class can be used for the associated target.  When omitted,
the target class should be available within the main namespace.

  profile => {
     class => 'Target::Class',
     target => 'target_method',
  }

=head3 object => Hashref

The object parameter works in conjunction with the class parameter and initialises
an object for the given class.  Upon dispatch, the target method is actioned against
the initialised object.

  profile => {
     class => 'Target::Class',
     target => 'target_method',
     object => {
        param1 => 'entry1',
        param2 => 'entry2',
     }
  }

=head1 AUTHOR

James Spurin <james@spurin.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by James Spurin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
