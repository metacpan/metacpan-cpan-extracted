package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionNames;
  use Moose;
  use IO::K8s;

  has 'categories' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'listKind' => (is => 'ro', isa => 'Str'  );
  has 'plural' => (is => 'ro', isa => 'Str'  );
  has 'shortNames' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'singular' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
