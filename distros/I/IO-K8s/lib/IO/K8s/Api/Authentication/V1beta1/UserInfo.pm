package IO::K8s::Api::Authentication::V1beta1::UserInfo;
  use Moose;
  use IO::K8s;

  has 'extra' => (is => 'ro', isa => 'HashRef[ArrayRef[Str]]'  );
  has 'groups' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'uid' => (is => 'ro', isa => 'Str'  );
  has 'username' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
