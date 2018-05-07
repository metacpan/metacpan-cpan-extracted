package IO::K8s::Api::Authorization::V1::NonResourceRule;
  use Moose;

  has 'nonResourceURLs' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'verbs' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
