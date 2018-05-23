package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResource;
  use Moose;
  use IO::K8s;

  has 'categories' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'group' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'namespaced' => (is => 'ro', isa => 'Bool'  );
  has 'shortNames' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'singularName' => (is => 'ro', isa => 'Str'  );
  has 'verbs' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'version' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
