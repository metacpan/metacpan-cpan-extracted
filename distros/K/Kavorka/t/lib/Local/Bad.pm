use v5.14;
use warnings;

package Local::Bad;

use Kavorka;

sub create {
	my ($class, $config) = @_;
	return $foo->bar($config);
}

method delete { ... }

1;

