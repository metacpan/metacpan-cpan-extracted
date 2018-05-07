package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement;
  use Moose;

  has 'key' => (is => 'ro', isa => 'Str'  );
  has 'operator' => (is => 'ro', isa => 'Str'  );
  has 'values' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
