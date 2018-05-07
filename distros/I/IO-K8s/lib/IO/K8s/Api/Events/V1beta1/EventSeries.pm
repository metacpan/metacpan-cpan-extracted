package IO::K8s::Api::Events::V1beta1::EventSeries;
  use Moose;

  has 'count' => (is => 'ro', isa => 'Int'  );
  has 'lastObservedTime' => (is => 'ro', isa => 'Str'  );
  has 'state' => (is => 'ro', isa => 'Str'  );
1;
