package IO::K8s::Api::Core::V1::GitRepoVolumeSource;
  use Moose;

  has 'directory' => (is => 'ro', isa => 'Str'  );
  has 'repository' => (is => 'ro', isa => 'Str'  );
  has 'revision' => (is => 'ro', isa => 'Str'  );
1;
