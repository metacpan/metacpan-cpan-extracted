package IO::K8s::Apimachinery::Pkg::Version::Info;
  use Moose;
  use IO::K8s;

  has 'buildDate' => (is => 'ro', isa => 'Str'  );
  has 'compiler' => (is => 'ro', isa => 'Str'  );
  has 'gitCommit' => (is => 'ro', isa => 'Str'  );
  has 'gitTreeState' => (is => 'ro', isa => 'Str'  );
  has 'gitVersion' => (is => 'ro', isa => 'Str'  );
  has 'goVersion' => (is => 'ro', isa => 'Str'  );
  has 'major' => (is => 'ro', isa => 'Str'  );
  has 'minor' => (is => 'ro', isa => 'Str'  );
  has 'platform' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
