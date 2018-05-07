package IO::K8s::Api::Storage::V1beta1::VolumeAttachmentStatus;
  use Moose;

  has 'attached' => (is => 'ro', isa => 'Bool'  );
  has 'attachError' => (is => 'ro', isa => 'IO::K8s::Api::Storage::V1beta1::VolumeError'  );
  has 'attachmentMetadata' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'detachError' => (is => 'ro', isa => 'IO::K8s::Api::Storage::V1beta1::VolumeError'  );
1;
