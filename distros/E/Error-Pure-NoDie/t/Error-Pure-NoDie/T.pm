package T;

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::NoDie qw(err);

# Example err function.
sub example {
	err 'Something.';
}

1;
