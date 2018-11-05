package Docker::Registry::GCE;
  use Moo;
  use Types::Standard qw/Str Maybe/;
  extends 'Docker::Registry::V2';

  has region => (is => 'ro', isa => Maybe[Str], default => undef);

  has '+url' => (lazy => 1, default => sub {
    my $self = shift;
    if (defined $self->region) {
      sprintf 'https://%s.gcr.io', $self->region;
    } else {
      'https://gcr.io';
    }
  });

1;
