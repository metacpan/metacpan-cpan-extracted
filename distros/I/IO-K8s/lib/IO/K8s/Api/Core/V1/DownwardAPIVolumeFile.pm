package IO::K8s::Api::Core::V1::DownwardAPIVolumeFile;
  use Moose;
  use IO::K8s;

  has 'fieldRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ObjectFieldSelector'  );
  has 'mode' => (is => 'ro', isa => 'Int'  );
  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'resourceFieldRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ResourceFieldSelector'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
