package Kubernetes::REST::HTTPResponse;
  use Moo;
  use Types::Standard qw/Str Int/;

  has content => (is => 'ro', isa => Str);
  has status => (is => 'ro', isa => Int);

1;
