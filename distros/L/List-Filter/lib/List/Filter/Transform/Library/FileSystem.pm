package List::Filter::Transform::Library::FileSystem;
use base qw( Class::Base );


=head1 NAME

List::Filter::Transform::Library::FileSystem - transforms for working with unix file listings

=head1 SYNOPSIS

   # This is a plugin, not intended for direct use.
   # See: List::Filter::Storage::CODE

=head1 DESCRIPTION

A library of standard List::Filter "transforms" for working with
unix file listings.

See L<List::Filter::Transform::Library::Documentation>
for information about the transforms defined by this module.

=head2 filters

The following is a (most likely partialy) listing of named
filters are defined by this module.

Note that all follow the "leading colon" naming convention.

=over

=item  :dwim_upcaret

Returns a transform to be used on regexps that are intended
to pick entries out of unix file system listings:

It converts a leading "^" in a regexp into a "\b", except when
it looks like you really meant to match the beginning of the
string, which in a file listing is typically relatively uninteresting,
e.g.

   /usr/share/bin/this
   /usr/share/bin/that
   /usr/share/bin/theother
   ...

=back

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );

our $VERSION = '0.01';
my  $DEBUG = 0;

=head2 METHODS

=over

=item new

Instantiates a new List::Filter::Profile object.

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

With no arguments, the newly created profile will be empty.

=cut

# Note: "new" (inherited from Class::Base)
# calls the following "init" routine automatically.

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

  my $storage_handler = List::Filter::Storage->new( storage =>
                                                    { format => 'MEM', } );

  # define new attributes
  my $attributes = {
           storage_handler => $args->{ storage_handler} || $storage_handler,
           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  lock_keys( %{ $self } );
  return $self;
}

=item define_filters_href

=cut

sub define_filters_href {
  my $self = shift;
  my $transforms =
    {
     ':dwim_upcaret' =>
     {
      'description' => "leading '^' converted to \\b, unless it's '^/' or '^~'",
      'method'      => 'sequential',
      'terms'       =>
      [
        [
         ' ^ \^ (?![/~]) | (?<=\|) \^ (?![/~]) ',
         'xg',
         '\\b'],
      ],
      'modifiers'   => "x",
     },

    };
  return $transforms;
}



=back

=head2 basic setters and getters

=over

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



1;

=back

=head1 SEE ALSO

L<List::Filter>
L<List::Filter::Project>

L<List::Filter::App::Relate>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
24 May 2007

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
