use strict;
use warnings;

END {
    ::diag 'status of filehandles: ', ::explain +{
        '-t STDIN' => -t STDIN,
        '-t STDOUT' => -t STDOUT,
        '-f STDOUT' => -f STDOUT,
        '-c STDOUT' => -c STDOUT,
    } if $^O eq 'MSWin32' or "$]" < '5.016' or not Test::Builder->new->is_passing;
}

1;
