package IO::K8s::Api::Apps::V1beta1::DeploymentRollback;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'rollbackTo' => (is => 'ro', isa => 'IO::K8s::Api::Apps::V1beta1::RollbackConfig'  );
  has 'updatedAnnotations' => (is => 'ro', isa => 'HashRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
