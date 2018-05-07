package IO::K8s::Api::Core::V1::ISCSIVolumeSource;
  use Moose;

  has 'chapAuthDiscovery' => (is => 'ro', isa => 'Bool'  );
  has 'chapAuthSession' => (is => 'ro', isa => 'Bool'  );
  has 'fsType' => (is => 'ro', isa => 'Str'  );
  has 'initiatorName' => (is => 'ro', isa => 'Str'  );
  has 'iqn' => (is => 'ro', isa => 'Str'  );
  has 'iscsiInterface' => (is => 'ro', isa => 'Str'  );
  has 'lun' => (is => 'ro', isa => 'Int'  );
  has 'portals' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'secretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LocalObjectReference'  );
  has 'targetPortal' => (is => 'ro', isa => 'Str'  );
1;
