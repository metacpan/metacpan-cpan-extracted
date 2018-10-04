package MyTestUtils;
use strict;
use warnings;

sub _try {
    my $code = shift;
    eval { $code->(); 1; }
    or do {
        my $error = $@ || 'Zombie error';
        return $error;
    };

    return;
}

1;
