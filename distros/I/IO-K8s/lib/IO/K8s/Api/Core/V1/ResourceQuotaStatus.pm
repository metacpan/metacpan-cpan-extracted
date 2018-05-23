package IO::K8s::Api::Core::V1::ResourceQuotaStatus;
  use Moose;
  use IO::K8s;

  has 'hard' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'used' => (is => 'ro', isa => 'HashRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
