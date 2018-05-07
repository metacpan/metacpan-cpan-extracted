package IO::K8s::Api::Core::V1::Taint;
  use Moose;

  has 'effect' => (is => 'ro', isa => 'Str'  );
  has 'key' => (is => 'ro', isa => 'Str'  );
  has 'timeAdded' => (is => 'ro', isa => 'Str'  );
  has 'value' => (is => 'ro', isa => 'Str'  );
1;
