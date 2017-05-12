package List::Filter::Transform::Internal;
use base qw( Class::Base );

=head1 NAME

List::Filter::Transform::Internal - common operations used by transform methods

=head1 SYNOPSIS

   # using as a utility object
   use List::Filter::Transform::Internal;
   my $lftu = List::Filter::Transform::Internal->new();
   $term = [ qr{ slimey \s+ boss }x, 'g', 'professional management' ];
   $changed_item = $lftu->substitute( $item, $term );


   # one way of setting override_modifiers attribute (case insensitve, "i")
   my $lftu = List::Filter::Transform::Internal->new( {override_modifiers => 'i' } );

   # another way of setting override_modifiers (extended regexps, "x"):
   $lftu->set_override_modifiers( 'x' );


   # this can be inherited from (deprecated):
   use base ("List::Filter::Transform::Internal");
   my $changed = $self->substitute( $item, $term );


=head1 DESCRIPTION

List::Filter::Transform::Internal is at present a class of utility
object, used by the List::Filter::Transforms::* modules,
which contain "methods" that are exported to the Dispatcher
namespace ultimately.

At present, there is only one object attribute that's important:
  "override_modifiers"
which is used by the "substitute" method.

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

our $VERSION = '0.01';

=item new

Instantiates a new List::Filter::Transforms::* object.

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

With no arguments, the newly created filter will be empty.

=cut

# Note:
# "new" is inherited from Class::Base.
# It calls the following "init" routine automatically.

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

  # define new attributes
  my $attributes = {
           override_modifiers => $args->{ override_modifiers },
           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  lock_keys( %{ $self } );
  return $self;
}


=back

=head2 methods internally used by transforms

=over

=item substitute

Performs a perl s/// on the given string, building up the the
substitution from three parts supplied in a an array ref:

(1) a perl regular expression, qr{}; (2) any external match
modifiers (e.g. "g", "e"); (3) the replacement string (or
expression, if the 'e' modifier is in use).

Some attempt has been made to avoid re-compiling the regular
expressions if there's no need to.  To take advantage of this, if
at all possible, the "ismx" modifiers should be applied when
creating the regexp.  The "g" and "e" modififiers are the only ones
that need to be applied externally.  The "o" modifier is silently ignored.

Inputs:
(1) the string to be modified
(2) a "transform term" (aref, three parts),

Returns: the modified string

Example:
   $term = [ qr{ slimey \s+ boss }x, 'g', 'professional management' ];
   $self->set_override_modifiers( 'x' );
   $fixed_item = $self->substitute( $item, $term );

=cut

sub substitute {
  my $self = shift;
  my $item = shift;
  my $term = shift;

  my $override_modifiers = $self->override_modifiers;

  my $regexp  = $term->[0];
  my $replace = $term->[2];
  my $mods    = $term->[1]  || $override_modifiers;

  if ($mods) { # just skip this stuff if there aren't any

    # Note: perl s/// mods are "egimosx", but only "imsx" are regexp attributes

    # extract modifiers that can be applied internally to the regexp
    my @internal = qw( i m s x );
    my $re_mods = '';
    foreach my $c (@internal) {
      if ( $mods =~ m/$c/ ) {
        $re_mods .= $c;
      }
    }
    # prepend internal mods to regexp in (?imsx) form
    if ($re_mods) { # don't mess with precompiled regexp if we don't need to
      $regexp = $self->mod_regexp( $regexp, $re_mods );
    }

    # silently ignore 'o' if present
    $mods =~ s/o//;

    # two valid posibilites remain: g and e, so we cover all 4 permutations:
    my $g_flag = ($mods =~ m/g/);
    my $e_flag = ($mods =~ m/e/);

    if ($g_flag && $e_flag) {
      $item =~ s{$regexp}{$replace}ge;
    } elsif ($g_flag) {
      $item =~ s{$regexp}{$replace}g;
    } elsif ($e_flag) {
      $item =~ s{$regexp}{$replace}e;
    } else {
      $item =~ s{$regexp}{$replace};
    }
  } else {   # no late modifiers, so do the simplest (fastest) thing
    $item =~ s{$regexp}{$replace};
  }
  return $item;
}

=item mod_regexp

Given a qr{} value and a set of modifiers (any of xism),
returns a qr{} value with those modifiers applied.

Inputs:
(1)  qr{}
(2) string: some sub-set of "xism"

Return: qr{}

(This is an inheritable "method", though it makes no use of
object or class data.)

=cut

sub mod_regexp {
  my $self   = shift;
  my $regexp = shift;
  my $mods   = shift;

  $self->debug("mod_regexp in Transforms.pm:\n");

  # Strip the "(?-xism:" and ")" from a qr{} value. They look like:
  #   qr/(?-xism:bush-league of whirled crime)/;

  $self->debug("regexp:>>>", $regexp, "<<<\n");

  my $intermed;
  if (
      ($intermed = $regexp) =~ s{ ^ \( \? [-xism]*? : }{}x
     ) {
    $intermed =~ s/\)$//; # do the closing paren only if the leading one was stripped
  }

  $self->debug("mods:>>>",     $mods,     "<<<\n");
  $self->debug("intermed:>>>", $intermed, "<<<\n");

  # generate new regexp with modifiers applied internally
  my $new_regexp = qr{(?$mods:$intermed)};
  return $new_regexp;
}

=back

=head2 basic setters and getters

=over

=item override_modifiers

Getter for object attribute override_modifiers

=cut

sub override_modifiers {
  my $self = shift;
  my $override_modifiers = $self->{ override_modifiers };
  return $override_modifiers;
}

=item set_override_modifiers

Setter for object attribute set_override_modifiers

=cut

sub set_override_modifiers {
  my $self = shift;
  my $override_modifiers = shift;
  $self->{ override_modifiers } = $override_modifiers;
  return $override_modifiers;
}




1;

=back

=head1 SEE ALSO

L<List::Filter>

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
