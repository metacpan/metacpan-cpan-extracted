package Flower::Nodes;

use 5.12.0;

use strict;
use warnings;

use Data::UUID;
use Flower::Node;

use Scalar::Util qw/refaddr/;

use Carp qw/confess/;

my $our_uuid = Data::UUID->new->create_str;

sub new {

  my $class     = shift;
  my $self_ip   = shift;
  my $self_port = shift;

  confess "called as object method" if ref $class;

  my $self = {};
  bless $self, __PACKAGE__;

  # in the beginning we know only about ourself
  say
    "Creating a new set of nodes with first node ip: $self_ip, port $self_port";
  my $us = Flower::Node->new(
    { ip     => $self_ip,
      uuid   => $our_uuid,
      port   => $self_port,
      parent => $self
    }
  );
  $self->{nodes} = [$us];

  return $self;
}

sub self {
  my $self = shift;
  return $self->{nodes}->[0];
}

sub add {
  my $self = shift;
  my $node = shift;
  push @{ $self->{nodes} }, $node;
  return $self;
}

sub add_if_necessary {
  my $self = shift;
  my $args = shift;
  my $uuid = $args->{uuid};
  my $port = $args->{port};
  my $ip   = $args->{ip};

  foreach ( @{ $self->{nodes} } ) {
    return
      if ( $_->uuid && $uuid && ( $_->uuid eq $uuid ) );    # we know this one
    return
      if ( ( $_->ip eq $ip ) && ( $_->port eq $port ) )
      ;    # this looks like us, do not add
  }
  my $node = Flower::Node->new(
    { uuid => $uuid, port => $port, ip => $ip, parent => $self } );
  push @{ $self->{nodes} }, $node;
  say "$node added";
  return 1;
}

sub remove {
  my $self = shift;
  my $node = shift;
  $self->{nodes} = [
    map {
      if   ( refaddr($_) ne refaddr($node) ) {$_}
      else                                   { () }
      } @{ $self->{nodes} }
  ];
  return $self;
}

sub list {
  my $self = shift;
  return @{ $self->{nodes} };
}

sub nodes_as_hashref {
  my $self = shift;
  return [ map { { uuid => $_->uuid, ip => $_->ip, port => $_->port } }
      @{ $self->{nodes} } ];
}

sub update {
  my $self = shift;

  foreach my $node ( @{ $self->{nodes} } ) {

    # if node has timed out, remove it
    if ( $node->has_timed_out ) {
      print "$node - removing after timeout\n";
      $self->remove($node);
    }

    # ping it if we need to, to keep it alive
    else {

      # tell the node what the 'us' node is, so it can pass that
      # information on
      $node->ping_if_necessary( $self->nodes_as_hashref );
    }
  }

  say "current nodes:";
  foreach my $node ( @{ $self->{nodes} } ) {
    if ( $node->has_files_object ) {
      say " * $node (" . $node->files->count . " files)";
    }
    else {
      say " * $node (no files yet)";
    }

  }

}

1;
