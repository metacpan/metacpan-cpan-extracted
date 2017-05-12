use strict;
use warnings FATAL => 'all';

package HTML::Tested::Test::Upload;
use base 'HTML::Tested::Test::Value';

sub convert_to_param {
	my ($class, $obj_class, $r, $name, $val) = @_;
	$r->add_upload($name, $val);
}

1;
