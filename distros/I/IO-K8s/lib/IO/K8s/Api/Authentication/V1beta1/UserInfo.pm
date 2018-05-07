package IO::K8s::Api::Authentication::V1beta1::UserInfo;
  use Moose;

  has 'extra' => (is => 'ro', isa => 'HashRef[ArrayRef[Str]]'  );
  has 'groups' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'uid' => (is => 'ro', isa => 'Str'  );
  has 'username' => (is => 'ro', isa => 'Str'  );
1;
