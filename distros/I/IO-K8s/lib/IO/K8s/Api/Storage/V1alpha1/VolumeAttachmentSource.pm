package IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentSource;
  use Moose;

  has 'persistentVolumeName' => (is => 'ro', isa => 'Str'  );
1;
