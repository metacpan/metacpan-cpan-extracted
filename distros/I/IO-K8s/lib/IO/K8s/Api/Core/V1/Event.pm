package IO::K8s::Api::Core::V1::Event;
  use Moose;
  use IO::K8s;

  has 'action' => (is => 'ro', isa => 'Str'  );
  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'count' => (is => 'ro', isa => 'Int'  );
  has 'eventTime' => (is => 'ro', isa => 'Str'  );
  has 'firstTimestamp' => (is => 'ro', isa => 'Str'  );
  has 'involvedObject' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ObjectReference'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'lastTimestamp' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'related' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ObjectReference'  );
  has 'reportingComponent' => (is => 'ro', isa => 'Str'  );
  has 'reportingInstance' => (is => 'ro', isa => 'Str'  );
  has 'series' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::EventSeries'  );
  has 'source' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::EventSource'  );
  has 'type' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
