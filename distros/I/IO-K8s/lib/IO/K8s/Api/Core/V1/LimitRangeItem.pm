package IO::K8s::Api::Core::V1::LimitRangeItem;
  use Moose;
  use IO::K8s;

  has 'default' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'defaultRequest' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'max' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'maxLimitRequestRatio' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'min' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'type' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
