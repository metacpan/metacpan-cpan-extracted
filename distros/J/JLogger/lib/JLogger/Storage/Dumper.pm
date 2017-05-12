package JLogger::Storage::Dumper;

use strict;
use warnings;

use base 'JLogger::Storage';

use Data::Dumper;

sub store {
    my ($self, $message) = @_;

    print Dumper $message;
}

1;
