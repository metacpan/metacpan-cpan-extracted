package List::Filter::Transform;
use base qw( List::Filter );

=head1 NAME

List::Filter::Transform - lists of find-and-replace operations

=head1 SYNOPSIS

   use List::Filter::Transform;

   @terms = ( [ 'subroutine', 'gi', 'method' ],
              { 'field',      'gi', 'attribute' ],
              { 'functional', 'gi', 'not broken' ],
             );

   my $filter = List::Filter::Transform->new(
     { name         => 'oop_up_docs',
       terms        => \@terms ,
       description  =>
          "Hunt and destroy passe jargon in docs for spiffy OOP code.",
       modifiers    => "gi",  # redundant with settings in @terms
     } );  # Letting method default to 'sequential'



   # If non-standard behavior is desired in locating the methods via plugins
   my $filter = List::Filter::Transform->new(
     { name              => 'oop_up_docs',
       terms             => \@terms ,
       description       =>
          "Hunt and destroy passe jargon in docs for spiffy OOP code.",
       modifiers         => "g",
       method            => "reverse",
       plugin_root       => "List::Filter::Transform::Internal",
       plugin_exceptions => ["List::Filter::Transforms::NotThisOne"],

     } );

   # alternately
   my $filter = List::Filter::Transform->new();  # creates an empty filter

   my @terms = [ [ 'find_me', 'i', 'replace_with_this' ],
                 [ 'function', '', 'method' ],
                 [ 'variable', '', 'attribute' ],
                 [ 'Function', '', 'Method' ],
                 [ 'Variable', '', 'Attribute' ],
               ];
   $filter->set_name('oop_up_docs');
   $filter->set_terms( \@terms );
   $filter->set_method('sequential');  # typical
   $filter->set_description(
             "Hunt and destroy passe jargon in docs for spiffy OOP code.");
   $filter->set_modifiers( "g" ); # 'g' applied, uh, 'globally'



=head1 DESCRIPTION

A "transform" is like a List::Filter "filter" (L<List::Filter>),
except that each pattern has an associated replacement expression.
A "transform" is essentially a list of perl substitutions ("s///").

At the core of a transform object is the "terms" attribute, an
array of arrays of three values:

(1) a perl regular expression,
(2) external match modifiers (e.g. 'g'),
(3) the replacement expression to substitute for a match

Note: future versions of this code may have support for
(4) (optional) a hashref of miscellanious transform attributes.

As with "filters", each transform has a "method" field which
specifies how the transform will be used by default.  It is
expected that applying the substitutions in sequence will be
used so frequently, that the default method itself defaults
to "sequential".

Valid methods are defined in the List::Filter::Transforms::*
modules, by default.  And alternate location can be selected
with the "plugins_tree" argument, and plugin modules in the
tree can be selectively ignored if named in the "plugin_exceptions"
array.

As of this writing, the only standard supported transform method
is "sequential".


=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
my $DEBUG = 0;
use Carp;
use Data::Dumper;
use Hash::Util qw( unlock_keys lock_keys );

our $VERSION = '0.01';

=item new

Instantiates a new List::Filter::Transform object.
Inherits from L<List::Filter>.

=cut

=item init

Initialize object attributes and then lock them down to prevent
accidental creation of new ones.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  # make sure the dispatcher is generated for Transforms, not Filters.
  my $class = __PACKAGE__;
  $args->{ plugin_root } ||= $class . 's';

  # $self->$parent::init( $args );
  $self->SUPER::init( $args );

  my $attributes =
    {
     name         => $args->{ name }        || $self->{ name },
     method       => $args->{ method }      || $self->{ method }       || 'sequential',
     description  => $args->{ description } || $self->{ description },
     terms        => $args->{ terms }       || $self->{ terms },
     modifiers    => $args->{ modifiers }   || $self->{ modifiers },
     dispatcher   => $args->{ dispatcher }  || $self->{ dispatcher },
    };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields }; # hash slice

  lock_keys( %{ $self } );
  return $self;
}

=back

=head2 basic setters and getters

Note: these accessors are all inherited from L<List::Filter>

=over

=item name

Getter for object attribute name

=item set_name

Setter for object attribute set_name

=item method

Getter for object attribute method

=item set_method

Setter for object attribute set_method

=item description

Getter for object attribute description

=item set_description

Setter for object attribute set_description

=item terms

Getter for object attribute terms

=item set_terms

Setter for object attribute set_terms

=item modifiers

Getter for object attribute modifiers

=item set_modifiers

Setter for object attribute set_modifiers

=item dispatcher

Getter for object attribute dispatcher

=item set_dispatcher

Setter for object attribute set_dispatcher

=cut

1;

=head1 SEE ALSO

L<List::Filter>
L<List::Filter::Project>

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
