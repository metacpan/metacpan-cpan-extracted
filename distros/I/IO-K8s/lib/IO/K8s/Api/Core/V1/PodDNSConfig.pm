package IO::K8s::Api::Core::V1::PodDNSConfig;
  use Moose;
  use IO::K8s;

  has 'nameservers' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'options' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::PodDNSConfigOption]'  );
  has 'searches' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
