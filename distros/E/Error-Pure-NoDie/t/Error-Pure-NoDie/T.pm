package T;

use strict;
use warnings;

use Error::Pure::NoDie qw(err);

# Example err function.
sub example {
	err 'Something.';
}

1;
