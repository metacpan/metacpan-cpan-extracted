package List::Filter::Dispatcher;
use base qw( Class::Base );

=head1 NAME

List::Filter::Dispatcher -

=head1 SYNOPSIS

   use List::Filter::Dispatcher;
   my $dispatcher = List::Filter::Dispatcher->new(
             { plugin_root       => 'List::Filter::Filters',
               plugin_exceptions => 'List::Filter::Filters::Ext::Nogoodnik',
               } );
   my $aref_out = $dispatcher->apply( $filter, $aref_in );

=head1 DESCRIPTION

The Dispatcher object is told where to look for modules that
contain the methods that can apply a L<List::Filter> filter.
During it's init phase the dispatcher does the necessary requires
of each of those method-supplying modules, which must be designed
to export these methods to the Dispatcher's namespace.

It's expected that when a new Filter object (or one of it's
inheritors) is created, it will be assigned a dispatcher so that
it will be able to execute the filter's methods.  See
L<List::Filter>.


=head2 MOTIVATION

This is part of an extension mechanism to allow the creation of
additional filter filter methods that the existing code framework
will be able to use without modification.

One advantage of this approach is that each filter object has a
default method (accessed via the L<apply> method), and yet it can
be applied with a different method if that seems desireable.

For example: an "omit" filter could be inverted to display
only the items that are usually omitted.

See L<"List::Filter::Project/Extension mechanisms"> for
instructions on writing methods, and creating filters that use
them.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
my $DEBUG = 0;
use Carp;
use Data::Dumper;
use Hash::Util qw(lock_keys unlock_keys);
use Module::List qw(list_modules);

use Module::List::Pluggable qw( list_modules_under import_modules );

our $VERSION = '0.01';

=item new

Instantiates a new List::Filter::Dispatcher object.

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes:

=over

=item plugin_root

The location to look for the "plugins" that define the actual
"methods" that tasks are dispatched to.

=item plugin_exceptions

A list of modules in the plugin_root that will be ignored.

Note: if you absolutely must use inheritence to create a variant
of an existing plugin, the original parent class should be
entered in this list to avoid namespace collisions.

=back

=cut

# Note:
# "new" is inherited from Class::Base.
# It calls the following "init" routine automatically.

=item init

Initialize object attributes and then lock them down to prevent
accidental creation of new ones.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  # define new attributes
  my $attributes = {
                    plugin_root      => $args->{ plugin_root },
           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  $self->do_require_of_plugins;

  lock_keys( %{ $self } );
  return $self;
}


=item do_require_of_plugins

An internally used routine that loads all of the subs defined in
all of the plugins/extensions found in perl's module namespace
at or under the "plugin_root" location.

Returns: the number of sucessfully loaded plugin modules.

=cut

sub do_require_of_plugins {
  my $self = shift;
  my $plugin_root =       $self->plugin_root;
  my $plugin_exceptions = $self->plugin_exceptions;

  # See Module::List::Pluggable
  import_modules( $plugin_root, {
                                 exceptions => $plugin_exceptions,
                               });
}


=item apply

Applies the filter object, typically acting as a filter.

Inputs:
(1) filter object (note: contains an array of patterns)
(2) aref of input items to be operated on
(3) an options hash reference:

Supported option(s):

  "method" -- routine to use to apply filter to input items
    (defaults to method specified inside the filter).

Return:
aref of output items

Note:
The options href is also passed through to the "method" routine.

=cut

sub apply {
  my $self        = shift;
  my $filter      = shift;
  my $items       = shift;
  my $opt         = shift;

  my $method      = $opt->{ method } || $filter->method;

  my $output_aref = $self->$method( $filter, $items, $opt );
  return $output_aref;
}

=back

=head2 accessors (setters and getters)

Note: because of the oddities of the current architecture,
accessors must be provided for any fields needed by either the
Filter or the Transform routines, since those are imported into
the Dispatcher namespace, they become Dispatcher methods.

I'm making an effort to document them here, for that reason
(though in general I think they should be avoided, period).

=over

=item plugin_root

Getter for object attribute plugin_root

=cut

sub plugin_root {
  my $self = shift;
  my $plugin_root = $self->{ plugin_root };
  return $plugin_root;
}

=item set_plugin_root

Setter for object attribute set_plugin_root

=cut

sub set_plugin_root {
  my $self = shift;
  my $plugin_root = shift;
  $self->{ plugin_root } = $plugin_root;
  return $plugin_root;
}



=item plugin_exceptions

Getter for object attribute plugin_exceptions

=cut

sub plugin_exceptions {
  my $self = shift;
  my $plugin_exceptions = $self->{ plugin_exceptions };
  return $plugin_exceptions;
}

=item set_plugin_exceptions

Setter for object attribute set_plugin_exceptions

=cut

sub set_plugin_exceptions {
  my $self = shift;
  my $plugin_exceptions = shift;
  $self->{ plugin_exceptions } = $plugin_exceptions;
  return $plugin_exceptions;
}


1;

=head1 SEE ALSO

L<List::Filter>
L<Module::List::Pluggable>

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
