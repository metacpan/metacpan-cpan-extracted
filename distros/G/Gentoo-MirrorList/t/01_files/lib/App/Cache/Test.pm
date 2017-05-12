package    # HIDE ME
  App::Cache::Test;

# ABSTRACT: A Dead Shadow in front of App::Cache;

# Fakes being App::Cache with Moose.

use strict;
use warnings;
use Moose;
use Carp ();
use App::Cache;

#extends 'App::Cache';
use namespace::autoclean;

has 'mirror_file' => ( isa => 'Str', is => 'rw', required => 1 );

has 'stash' => ( isa => 'HashRef', is => 'rw', default => sub { +{} } );

sub get {
  my ( $self, $argzero ) = @_;
  if ( exists $self->stash->{$argzero} ) {
    return $self->stash->{$argzero};
  }
  return;
}

sub set {
  my ( $self, $argzero, $argval ) = @_;
  $self->stash->{$argzero} = $argval;
  return;
}

sub get_url {
  my ( $self, $argzero ) = @_;
  if ( $argzero eq 'http://www.gentoo.org/main/en/mirrors3.xml' ) {
    open( my $fh, '<', $self->mirror_file ) or Carp::confess('Test File missing');
    local $/ = undef;
    return scalar <$fh>;
  }
}

__PACKAGE__->meta->make_immutable;

# HACKY.
# Moose makes our ->new anyway.
# This is just so we can lie about what we are.
#
our @ISA;
push @ISA, 'App::Cache';

no Moose;
1;

