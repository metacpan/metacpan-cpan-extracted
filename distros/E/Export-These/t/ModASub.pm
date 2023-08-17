package ModASub;

use Export::These;
use parent "ModA";

sub _reexport {
  my ($package, $target, @names)=@_;
  $package->SUPER::import(@names);
}

1;
