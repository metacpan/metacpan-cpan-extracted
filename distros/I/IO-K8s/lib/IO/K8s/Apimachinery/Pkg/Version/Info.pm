package IO::K8s::Apimachinery::Pkg::Version::Info;
  use Moose;

  has 'buildDate' => (is => 'ro', isa => 'Str'  );
  has 'compiler' => (is => 'ro', isa => 'Str'  );
  has 'gitCommit' => (is => 'ro', isa => 'Str'  );
  has 'gitTreeState' => (is => 'ro', isa => 'Str'  );
  has 'gitVersion' => (is => 'ro', isa => 'Str'  );
  has 'goVersion' => (is => 'ro', isa => 'Str'  );
  has 'major' => (is => 'ro', isa => 'Str'  );
  has 'minor' => (is => 'ro', isa => 'Str'  );
  has 'platform' => (is => 'ro', isa => 'Str'  );
1;
