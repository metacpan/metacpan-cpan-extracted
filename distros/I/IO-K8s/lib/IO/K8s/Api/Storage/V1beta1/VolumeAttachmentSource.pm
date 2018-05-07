package IO::K8s::Api::Storage::V1beta1::VolumeAttachmentSource;
  use Moose;

  has 'persistentVolumeName' => (is => 'ro', isa => 'Str'  );
1;
