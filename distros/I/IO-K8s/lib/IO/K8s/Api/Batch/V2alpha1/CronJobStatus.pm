package IO::K8s::Api::Batch::V2alpha1::CronJobStatus;
  use Moose;
  use IO::K8s;

  has 'active' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::ObjectReference]'  );
  has 'lastScheduleTime' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
