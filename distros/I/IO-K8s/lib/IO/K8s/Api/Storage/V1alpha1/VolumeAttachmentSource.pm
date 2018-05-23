package IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentSource;
  use Moose;
  use IO::K8s;

  has 'persistentVolumeName' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
