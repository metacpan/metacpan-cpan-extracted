package IO::K8s::Api::Core::V1::GitRepoVolumeSource;
  use Moose;
  use IO::K8s;

  has 'directory' => (is => 'ro', isa => 'Str'  );
  has 'repository' => (is => 'ro', isa => 'Str'  );
  has 'revision' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
