package IO::K8s::Api::Core::V1::DownwardAPIVolumeFile;
  use Moose;

  has 'fieldRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ObjectFieldSelector'  );
  has 'mode' => (is => 'ro', isa => 'Int'  );
  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'resourceFieldRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ResourceFieldSelector'  );
1;
