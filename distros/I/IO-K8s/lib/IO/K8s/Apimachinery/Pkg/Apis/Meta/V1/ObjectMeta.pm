package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;
  use Moose;
  use IO::K8s;

  has 'annotations' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'clusterName' => (is => 'ro', isa => 'Str'  );
  has 'creationTimestamp' => (is => 'ro', isa => 'Str'  );
  has 'deletionGracePeriodSeconds' => (is => 'ro', isa => 'Int'  );
  has 'deletionTimestamp' => (is => 'ro', isa => 'Str'  );
  has 'finalizers' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'generateName' => (is => 'ro', isa => 'Str'  );
  has 'generation' => (is => 'ro', isa => 'Int'  );
  has 'initializers' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializers'  );
  has 'labels' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'namespace' => (is => 'ro', isa => 'Str'  );
  has 'ownerReferences' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::OwnerReference]'  );
  has 'resourceVersion' => (is => 'ro', isa => 'Str'  );
  has 'selfLink' => (is => 'ro', isa => 'Str'  );
  has 'uid' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
