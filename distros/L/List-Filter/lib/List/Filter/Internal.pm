package List::Filter::Internal;
use base qw( Class::Base );

=head1 NAME

List::Filter::Internal - internal methods for parameter qualification, etc.

=head1 SYNOPSIS

  use List::Filter::Internal;
  my $lfi = List::Filter::Internal->new( { default_stash => $default_stash } );
  my $storage = $lfi->qualify_storage( $args->{ storage } );

  # alternate (preferred?), creates:
  #   $HOME/.list-filter/filters.yaml
  my $lfi = List::Filter::Internal->new();
  my $storage = $lfi->qualify_storage_from_namespace(
                        $args->{ storage },
                        'filter',
                       );

=head1 DESCRIPTION

A collection of miscellanious utility methods expected to be used
only internally by L<List::Filter> and it's relatives.

The primary focus is on interface qualification routines that
need to be applied at various levels (since client code
might be written to access the system at any level), and hence
can't be part of any one class.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
my $DEBUG = 0;
use Carp qw(carp croak cluck confess);
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );
use Env qw( HOME );

use File::Path     qw(mkpath);
use File::Basename qw(fileparse basename dirname);
use File::Copy     qw(copy move);

our $VERSION = '0.01';

=item new

Instantiates a new List::Filter object.

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
           ### fill-in name/value pairs of attributes here
           # name          => $args->{ name },
           default_stash   => $args->{ default_stash },

           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  lock_keys( %{ $self } );
  return $self;
}


=item qualify storage

Qualifies the "storage" paramameter (used by L<List::Filter> and
it's relatives).

Input:  the storage argument (scalar or aref)

Return: the qualified storage argument (aref)

Note that this uses the object's "default_stash" argument (scalar)
as a fallback.

=cut

### if $storage is an aref, then it should contain scalars and hrefs.
### if it contains another aref, it should toss an error, or at least a
### warning: that's an indication of a typo, e.g. "storage => [ $storage ]".

sub qualify_storage {
  my $self          = shift;
  my $storage       = shift;
  my $default_stash = $self->default_stash;

  $storage = qualify_storage_guts( $storage, $default_stash );

  return $storage;
}

=item qualify_storage_from_namespace

Qualifies the "storage" paramameter (used by L<List::Filter> and
it's relatives).

Input: (1) the storage argument (scalar or aref)
       (2) the "namespace" to use to generate a fall back yaml file (scalar).

Return: the qualified storage argument (aref)

=cut


sub qualify_storage_from_namespace {
  my $self          = shift;
  my $storage       = shift;
  my $namespace     = shift;

  my $default_stash = $self->define_yaml_default( $namespace );

  $storage = qualify_storage_guts( $storage, $default_stash );

  return $storage;
}


# qualify_storage_guts is an internally used sub (yes, in the
# Internal.pm module), which exists because if both of the front
# end methods call a sub, then "caller(1)" can point at the place
# where either were called.  (If one method were to call the other,
# then it'd be a more complicated problem).
sub qualify_storage_guts {
  my  $storage       = shift;
  my  $default_stash = shift;
  my ($package, $file, $line) = caller(1);

  if (not ( ref $storage eq 'ARRAY' )) {
    $storage = [ $storage ];
  } else { # we've (probably) got an aref...
    # But no arefs are allowed inside the main aref
    foreach my $entry ( @{ $storage } ) {
      if ( ref $entry eq 'ARRAY' ) {
        confess "The storage parameter should not be an aref inside an aref, in $file at line $line";
      }
    }
  }

  # Make sure there's a defined entry in the aref, or use the default
  if ( defined( $storage->[0] ) ) {  # just the first one -- no point in going hogwild
    $storage = $storage;
  } else {
    $storage = [ $default_stash ];
    # # make sure the directory exists
    # mkpath( dirname( $default_stash ) ) or croak "Could not create location for $default_stash: $!";
  }
  return $storage;
}




=item define_yaml_default

Internally used routine defines the default filter storage location

Input:   basename (aka the namespace)
Output:  default yaml file to use for storage
  E.g.     $HOME/.list-filter/<namespace>s.yaml

(superceeds older define_storage_default in Handler.pm)

=cut

sub define_yaml_default {
  my $self      = shift;
  my $basename  = shift;

  # Using plural for default filename
  my $filename = $basename . 's'; # i18n? what's that?

  my $default = "$HOME/.list-filter/$filename.yaml";
  mkpath( dirname($default) );

#  my $storage = [ $default ];
#  $self->set_storage( $storage );
#  $self->set_write_storage ( $default );
  return $default;
}

=item default_stash

Getter for object attribute default_stash

=cut

sub default_stash {
  my $self = shift;
  my $default_stash = $self->{ default_stash };
  return $default_stash;
}

=item set_default_stash

Setter for object attribute set_default_stash

=cut

sub set_default_stash {
  my $self = shift;
  my $default_stash = shift;
  $self->{ default_stash } = $default_stash;
  return $default_stash;
}




1;

=back

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

