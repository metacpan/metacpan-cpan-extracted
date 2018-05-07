package IO::K8s::Api::Core::V1::ResourceQuotaStatus;
  use Moose;

  has 'hard' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'used' => (is => 'ro', isa => 'HashRef[Str]'  );
1;
