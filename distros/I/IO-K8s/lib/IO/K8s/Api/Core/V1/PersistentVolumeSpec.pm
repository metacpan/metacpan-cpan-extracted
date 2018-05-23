package IO::K8s::Api::Core::V1::PersistentVolumeSpec;
  use Moose;
  use IO::K8s;

  has 'accessModes' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'awsElasticBlockStore' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::AWSElasticBlockStoreVolumeSource'  );
  has 'azureDisk' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::AzureDiskVolumeSource'  );
  has 'azureFile' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::AzureFilePersistentVolumeSource'  );
  has 'capacity' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'cephfs' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::CephFSPersistentVolumeSource'  );
  has 'cinder' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::CinderVolumeSource'  );
  has 'claimRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ObjectReference'  );
  has 'csi' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::CSIPersistentVolumeSource'  );
  has 'fc' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::FCVolumeSource'  );
  has 'flexVolume' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::FlexPersistentVolumeSource'  );
  has 'flocker' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::FlockerVolumeSource'  );
  has 'gcePersistentDisk' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::GCEPersistentDiskVolumeSource'  );
  has 'glusterfs' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::GlusterfsVolumeSource'  );
  has 'hostPath' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::HostPathVolumeSource'  );
  has 'iscsi' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ISCSIPersistentVolumeSource'  );
  has 'local' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LocalVolumeSource'  );
  has 'mountOptions' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'nfs' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NFSVolumeSource'  );
  has 'nodeAffinity' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::VolumeNodeAffinity'  );
  has 'persistentVolumeReclaimPolicy' => (is => 'ro', isa => 'Str'  );
  has 'photonPersistentDisk' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PhotonPersistentDiskVolumeSource'  );
  has 'portworxVolume' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PortworxVolumeSource'  );
  has 'quobyte' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::QuobyteVolumeSource'  );
  has 'rbd' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::RBDPersistentVolumeSource'  );
  has 'scaleIO' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ScaleIOPersistentVolumeSource'  );
  has 'storageClassName' => (is => 'ro', isa => 'Str'  );
  has 'storageos' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::StorageOSPersistentVolumeSource'  );
  has 'volumeMode' => (is => 'ro', isa => 'Str'  );
  has 'vsphereVolume' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::VsphereVirtualDiskVolumeSource'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
