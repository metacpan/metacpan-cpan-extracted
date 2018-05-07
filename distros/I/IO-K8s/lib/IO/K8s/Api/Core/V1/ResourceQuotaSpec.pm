package IO::K8s::Api::Core::V1::ResourceQuotaSpec;
  use Moose;

  has 'hard' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'scopes' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
