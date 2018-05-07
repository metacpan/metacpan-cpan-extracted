package IO::K8s::Api::Core::V1::SELinuxOptions;
  use Moose;

  has 'level' => (is => 'ro', isa => 'Str'  );
  has 'role' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
  has 'user' => (is => 'ro', isa => 'Str'  );
1;
