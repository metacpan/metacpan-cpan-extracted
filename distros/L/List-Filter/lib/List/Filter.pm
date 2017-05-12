package List::Filter;
use base qw( Class::Base );
#                                doom@kzsu.stanford.edu
#                                07 Mar 2007

=head1 NAME

List::Filter - named, persistent, shared lists of patterns

=head1 SYNOPSIS

   use List::Filter;

   my $filter = List::Filter->new(
     { name         => 'skip_boring_stuff',
       terms        => ['-\.vb$', '\-.js$'],
       method       => 'skip_boring_stuff',
       description  => "Skip the really boring stuff",
       modifiers    => "xi",
     } );

   # If non-standard behavior is desired in locating the methods via plugins
   my $filter = List::Filter->new(
     { name         => 'skip_boring_stuff',
       terms        => ['-\.vb$', '\-.js$'],
       method       => 'skip_boring_stuff',
       description  => "Skip the really boring stuff",
       modifiers    => "xi",
       plugin_root  => 'List::Filter::Filters',
       plugin_exceptions => ["List::Filter::Transforms::NotThisOne"],

     } );


   # Alternately:
   my $filter = List::Filter->new();  # creates an *empty* filter

   my @terms = ['-\.vb$', '-\.js$'];
   $filter->set_name('skip_dull');
   $filter->set_terms( \@terms );
   $filter->set_method('skip_boring_stuff');
   $filter->set_description(
             "Skip the really boring stuff");
   $filter->set_modifiers( "xi" );


   # using a filter (using it's internally defined "method")
   my $output_items = $filter->apply( \@input_items );

   # using a filter, specifying an alternate "method"
   my $output_items = $filter->apply( \@input_items, "do_it_like_this" );



=head1 DESCRIPTION

The List::Filter system is a generalized, extensible way of
filtering a list of items by apply a stack of perl regular
expressions, with a persistant storage mechanism to allow
the sharing of filters between different applications.

A List::Filter filter would just be a container object (a hashref
with some accessor code), except that it also has an internally
generated "dispatcher" object, so that it knows how to "apply"
itself.

The "method" attribute of a filter object is indeed the name of
a method, but not one defined inside this module.  Instead
there's a "plug-in" system that allows the definition of new
methods without modification of the existing code.

See L<List::Filter::Project> for documentation of the system.

=head1 OBJECT ATTRIBUTES

=head2 filter attributes (stored associated with the given name)

=over

=item name

The name of the search filter.

=item terms

A list of filter items, e.g. search terms (essentially regexps).

=item method

The default method used to apply the search terms.

=item modifiers

Default modifiers to be applied to the search terms (essentially,
regexp modifiers, e.g. "i").

=item description

A short description of the search filter.

=back

=head2

=over

=item dispatcher

Internally used field that stores the dispatcher object, a handle used to apply
the filter according to it's "method".

=item storage_handler

### TODO  weirdly enough, I can't figure out where this gets set.
### if it isn't set, then the save method can't work.
### but if the following flag is set, the apply method calls
### the save method... do I ever set this flag at this level?

=item save_filters_when_used

### TODO

=back

=head1 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
my $DEBUG = 1;  # zero before ship
use Carp;
use Data::Dumper;
use Hash::Util qw( unlock_keys lock_keys );

use List::Filter::Dispatcher;
use Memoize;
memoize( 'generate_dispatcher' );

our $VERSION = '0.04';

=item new

Instantiates a new List::Filter object.

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes:

  name
  description
  terms
  method
  modifiers

With no arguments, the newly created filter will be empty.

There is also the attribute:

  storage_handler

which is intended to point to the storage handler set-up so that
the filter has the capbility of saving itself to storage later.
See L</"MOTIVATION"> below.

There's a related flag (typically set by the storage handler):

   save_filters_when_used

There are two additional optional arguments,

 plugin_root
 plugin_exceptions

That are used in creating the dispatcher object which locates the
code used to apply the filter (typically as specified by the
"method" attribute):

L<List::Filter::Dispatcher>

=cut

# Note:
# "new" is inherited from Class::Base, it calls the following
# "init" routine automatically

=item init

Initialize object attributes and then lock them down to prevent
accidental creation of new ones.

Note: there is no leading underscore on name "init", though it's
arguably an "internal" routine (i.e. not likely to be of use to
client code).

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  # Generate the dispatcher object, used to apply filter's method
  my $plugin_root       = $args->{ plugin_root };
  my $plugin_exceptions = $args->{ plugin_exceptions };

  my $dispatcher = $self->generate_dispatcher(
                              $plugin_root,
                              $plugin_exceptions,
                           );

  my $attributes = {
           name                   => $args->{ name },
           method                 => $args->{ method },
           description            => $args->{ description },
           terms                  => $args->{ terms },
           modifiers              => $args->{ modifiers },
           dispatcher             => $dispatcher,
           storage_handler        => $args->{ storage_handler },
           save_filters_when_used => $args->{ save_filters_when_used },
           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  lock_keys( %{ $self } );
  return $self;
}



=item generate_dispatcher

Generate the dispatcher object, used to apply a filter's method

=cut

sub generate_dispatcher {
  my $self              = shift;
  my $plugin_root       = shift;
  my $plugin_exceptions = shift;

  my $class = ref $self;     # smells funny in here, eh?

  my $default_plugin_root =
    {
     'List::Filter'            => 'List::Filter::Filters',    # note: irregular naming
     'List::Filter::Transform' => 'List::Filter::Transform::Internal',
    };

  unless( $plugin_root ) {
    # Convention: unless there's a specified alternative, just use
    # plural of the class name (i18n? Fergeddhaboudit.)
    my $default = $default_plugin_root->{ $class } || $class . 's';
    $plugin_root = $default;
  }

  my $dispatcher = List::Filter::Dispatcher->new(
             { plugin_root       => $plugin_root,
               plugin_exceptions => $plugin_exceptions,
             } );

  return $dispatcher;
}


=back

=head2 the stuff that does the Real Work

=over

=item apply

Apply applies the filter object, typically acting as a filter.

Inputs:
(1) aref of input items to be operated on
(2) method to use to apply filter to input items (optional)
  defaults to method specified inside the filter

Return:
aref of output items

=cut

# This is just a wrapper around the dispatcher's "apply".
# Note that here the filter creates a dispatcher, which then contains
# the filter that created it (ah, OOP 'metaphors'... ).
sub apply {
  my $self    = shift;
  my $items   = shift;
  my $method  = shift || $self->method;

  # save copy of filter to "write_storage" location before using it
  if ($self->save_filters_when_used) {
    $self->save;
  }

  $self->debug( "List::Filter apply: $method used on $items\n" );

  my $dispatcher = $self->dispatcher;

  my $output_aref
    = $dispatcher->apply( $self, # heh
                          $items,
                          { method => $method,
                          },
                        );

  return $output_aref;
}

=item save

Saves a copy of the filter to the using the storage_handler
stored inside the object.

=cut

sub save {
  my $self = shift;
  my $storage_handler = $self->storage_handler;

  $storage_handler->save( $self ); # if only it were always this easy...

  return $self;
}

=back

=head2 basic setters and getters

=over

=item name

Getter for object attribute name

=cut

sub name {
  my $self = shift;
  my $name = $self->{ name };
  return $name;
}

=item set_name

Setter for object attribute set_name

=cut

sub set_name {
  my $self = shift;
  my $name = shift;
  $self->{ name } = $name;
  return $name;
}

=item method

Getter for object attribute method

=cut

sub method {
  my $self = shift;
  my $method = $self->{ method };
  return $method;
}

=item set_method

Setter for object attribute set_method

=cut

sub set_method {
  my $self = shift;
  my $method = shift;
  $self->{ method } = $method;
  return $method;
}


=item description

Getter for object attribute description

=cut

sub description {
  my $self = shift;
  my $description = $self->{ description };
  return $description;
}

=item set_description

Setter for object attribute set_description

=cut

sub set_description {
  my $self = shift;
  my $description = shift;
  $self->{ description } = $description;
  return $description;
}


=item terms

Getter for object attribute terms

=cut

sub terms {
  my $self = shift;
  my $terms = $self->{ terms };
  return $terms;
}

=item set_terms

Setter for object attribute set_terms

=cut

sub set_terms {
  my $self = shift;
  my $terms = shift;
  $self->{ terms } = $terms;
  return $terms;
}


=item modifiers

Getter for object attribute modifiers

=cut

sub modifiers {
  my $self = shift;
  my $modifiers = $self->{ modifiers };
  return $modifiers;
}

=item set_modifiers

Setter for object attribute set_modifiers

=cut

sub set_modifiers {
  my $self = shift;
  my $modifiers = shift;
  $self->{ modifiers } = $modifiers;
  return $modifiers;
}


=item dispatcher

Getter for object attribute dispatcher

=cut

sub dispatcher {
  my $self = shift;
  my $dispatcher = $self->{ dispatcher };
  return $dispatcher;
}

=item set_dispatcher

Setter for object attribute set_dispatcher

=cut

sub set_dispatcher {
  my $self = shift;
  my $dispatcher = shift;
  $self->{ dispatcher } = $dispatcher;
  return $dispatcher;
}

=item storage_handler

Getter for object attribute storage_handler

=cut

sub storage_handler {
  my $self = shift;
  my $storage_handler = $self->{ storage_handler };
  return $storage_handler;
}

=item set_storage_handler

Setter for object attribute set_storage_handler

=cut

sub set_storage_handler {
  my $self = shift;
  my $storage_handler = shift;
  $self->{ storage_handler } = $storage_handler;
  return $storage_handler;
}


=item save_filters_when_used

Getter for object attribute save_filters_when_used

=cut

sub save_filters_when_used {
  my $self = shift;
  my $save_filters_when_used = $self->{ save_filters_when_used };
  return $save_filters_when_used;
}

=item set_save_filters_when_used

Setter for object attribute set_save_filters_when_used

=cut

sub set_save_filters_when_used {
  my $self = shift;
  my $save_filters_when_used = shift;
  $self->{ save_filters_when_used } = $save_filters_when_used;
  return $save_filters_when_used;
}




1;



=head1 MOTIVATION

=head2 Why not just an href?

Why do we have List::Filter objects instead of just
filter hash references?  There's the usual reasoning of using
abstraction to preserve flexibility (later, implementation can be
changed from href to aref, qualification code might be added to
the accessors, and so on).

It also makes a convenient place to ensure that a "lock_keys" has
been done before the href is used (to help catch typos during
development).

=head2 Why not a fixed method?

A more interesting question is why is there a "method" attribute
for each filter?  A more standard OOP approach to this kind of
polymorphism (each filter is supposed to know it should be used)
would be to simply have a class for each type of filter.

This would be inelegant for a few reasons:

(1) it would make the use of the filters more rigid.  the
internally specified "method" name is only the default way the
filter should be applied, there are cases where you might like
to deviate from it (e.g. you might invert an "omit" filter to do
a "select" to check just what it is you've been skipping).

(2) it would multiply classes for no good reason, and I think it
would make it a little clumsier to add new Filter "methods".


=head2 the storage handler framework (lookup/save)

Each filter can hold a pointer to it's "storage handler", which
is intended to be set by the "lookup" method of that handler as
the filter is returned. This gives the filter the capability to
save itself later, and that's not as crazy as it sounds (not
quite) because there's a path of storage locations, and the place
it's read from need not be where it's saved to).

The way it works normally (?) is that the storage handler
instructs the filter that when it is applied it will save a copy
of itself.  The storage write location is most likely going to be
a yaml file that the user has access to, but the storage read
location can be somewhere else (e.g. a "standard" filter, which
is defined in the code, and hence not writeable).  The idea here
is that any filter that you've used, you get an accessible copy
of, suitable for editing if you'd like to make changes.


=head1 SEE ALSO

L<List::Filter::Project>
L<List::Filter::Dispatcher>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
