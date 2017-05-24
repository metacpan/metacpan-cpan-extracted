
package Lab::GenericSignals;

use warnings;
use strict;

our $VERSION = '3.543';


use sigtrap 'handler' => \&abort_all, qw(normal-signals error-signals);

sub abort_all {
    foreach my $object ( @{Lab::Generic::OBJECTS} ) {
        $object->abort();
    }
    @{Lab::Generic::OBJECTS} = ();
    exit;
}

END {
    abort_all();
}

1;
