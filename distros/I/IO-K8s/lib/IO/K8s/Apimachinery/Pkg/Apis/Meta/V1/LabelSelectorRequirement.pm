package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement;
  use Moose;
  use IO::K8s;

  has 'key' => (is => 'ro', isa => 'Str'  );
  has 'operator' => (is => 'ro', isa => 'Str'  );
  has 'values' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
