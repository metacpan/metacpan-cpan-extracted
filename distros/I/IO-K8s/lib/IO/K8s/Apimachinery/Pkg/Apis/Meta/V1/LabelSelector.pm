package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector;
  use Moose;

  has 'matchExpressions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement]'  );
  has 'matchLabels' => (is => 'ro', isa => 'HashRef[Str]'  );
1;
