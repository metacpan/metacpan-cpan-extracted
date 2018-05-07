package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionNames;
  use Moose;

  has 'categories' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'listKind' => (is => 'ro', isa => 'Str'  );
  has 'plural' => (is => 'ro', isa => 'Str'  );
  has 'shortNames' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'singular' => (is => 'ro', isa => 'Str'  );
1;
