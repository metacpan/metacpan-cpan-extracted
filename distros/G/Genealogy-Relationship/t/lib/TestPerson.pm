package TestPerson;
use Moo;
use Types::Standard qw[Str Int InstanceOf Enum];

has id => (
  is => 'ro',
  isa => Str,
);

has name => (
  is => 'ro',
  isa => Str,
);

has parent => (
  is => 'ro',
  isa => InstanceOf['TestPerson'],
);

has gender => (
  is => 'ro',
  isa => Enum[qw[m f]],
);

1;
