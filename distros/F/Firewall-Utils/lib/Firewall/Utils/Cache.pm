package Firewall::Utils::Cache;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

has cache => ( is => 'ro', isa => 'HashRef[Ref]', default => sub { {} }, );

sub get {
  my $self = shift;
  return $self->locate(@_);
}

sub set {
  my $self = shift;
  confess "ERROR: must have at least one key and one value" if @_ < 2;
  my $value   = pop;
  my $lastKey = pop;
  my @keys    = @_;
  my @step;
  my $ref = $self->cache;
  while ( my $key = shift @keys ) {
    push @step, $key;
    if ( not exists $ref->{$key} ) {
      $ref->{$key} = undef;
    }
    $ref = $ref->{$key};
    if ( defined $ref and ref($ref) ne 'HASH' ) {
      confess "ERROR: cache->" . join( '->', @step ) . " not a valid HashRef";
    }
  }
  $ref->{$lastKey} = $value;
}

sub clear {
  my $self = shift;
  my @keys = @_;
  if (@keys) {
    my $lastKey = pop @keys;
    my $ref     = $self->locate(@keys);
    if ( defined $ref and ref($ref) eq 'HASH' ) {
      delete( $ref->{$lastKey} );
    }
  }
  else {
    $self->{cache} = {};
  }
}

sub locate {
  my $self = shift;
  my @keys = @_;
  my $ref  = $self->cache;
  while ( my $key = shift @keys ) {
    if ( not exists $ref->{$key} ) {
      $ref = undef;
      last;
    }
    $ref = $ref->{$key};
  }
  return $ref;
}

__PACKAGE__->meta->make_immutable;
1;
