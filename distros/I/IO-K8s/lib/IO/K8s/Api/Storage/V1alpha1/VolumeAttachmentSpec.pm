package IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentSpec;
  use Moose;
  use IO::K8s;

  has 'attacher' => (is => 'ro', isa => 'Str'  );
  has 'nodeName' => (is => 'ro', isa => 'Str'  );
  has 'source' => (is => 'ro', isa => 'IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentSource'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
