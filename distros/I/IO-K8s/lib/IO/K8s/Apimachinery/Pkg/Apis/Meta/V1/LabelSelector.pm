package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector;
  use Moose;
  use IO::K8s;

  has 'matchExpressions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement]'  );
  has 'matchLabels' => (is => 'ro', isa => 'HashRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
