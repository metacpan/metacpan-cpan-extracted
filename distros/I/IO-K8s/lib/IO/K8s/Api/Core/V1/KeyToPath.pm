package IO::K8s::Api::Core::V1::KeyToPath;
  use Moose;

  has 'key' => (is => 'ro', isa => 'Str'  );
  has 'mode' => (is => 'ro', isa => 'Int'  );
  has 'path' => (is => 'ro', isa => 'Str'  );
1;
