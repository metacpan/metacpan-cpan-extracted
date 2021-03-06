package IO::K8s::Api::Core::V1::Volume;
  use Moose;
  use IO::K8s;

  has 'awsElasticBlockStore' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::AWSElasticBlockStoreVolumeSource'  );
  has 'azureDisk' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::AzureDiskVolumeSource'  );
  has 'azureFile' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::AzureFileVolumeSource'  );
  has 'cephfs' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::CephFSVolumeSource'  );
  has 'cinder' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::CinderVolumeSource'  );
  has 'configMap' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ConfigMapVolumeSource'  );
  has 'downwardAPI' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::DownwardAPIVolumeSource'  );
  has 'emptyDir' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::EmptyDirVolumeSource'  );
  has 'fc' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::FCVolumeSource'  );
  has 'flexVolume' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::FlexVolumeSource'  );
  has 'flocker' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::FlockerVolumeSource'  );
  has 'gcePersistentDisk' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::GCEPersistentDiskVolumeSource'  );
  has 'gitRepo' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::GitRepoVolumeSource'  );
  has 'glusterfs' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::GlusterfsVolumeSource'  );
  has 'hostPath' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::HostPathVolumeSource'  );
  has 'iscsi' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ISCSIVolumeSource'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'nfs' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NFSVolumeSource'  );
  has 'persistentVolumeClaim' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PersistentVolumeClaimVolumeSource'  );
  has 'photonPersistentDisk' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PhotonPersistentDiskVolumeSource'  );
  has 'portworxVolume' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PortworxVolumeSource'  );
  has 'projected' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ProjectedVolumeSource'  );
  has 'quobyte' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::QuobyteVolumeSource'  );
  has 'rbd' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::RBDVolumeSource'  );
  has 'scaleIO' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ScaleIOVolumeSource'  );
  has 'secret' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecretVolumeSource'  );
  has 'storageos' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::StorageOSVolumeSource'  );
  has 'vsphereVolume' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::VsphereVirtualDiskVolumeSource'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
