package IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentStatus;
  use Moose;
  use IO::K8s;

  has 'attached' => (is => 'ro', isa => 'Bool'  );
  has 'attachError' => (is => 'ro', isa => 'IO::K8s::Api::Storage::V1alpha1::VolumeError'  );
  has 'attachmentMetadata' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'detachError' => (is => 'ro', isa => 'IO::K8s::Api::Storage::V1alpha1::VolumeError'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
