use strict;
use warnings;

use IO::Scalar;

open SAVEOUT, ">&STDOUT";
print SAVEOUT "";

my $buffer = "";

tie *STDOUT, 'IO::Scalar', \$buffer;

sub reset_out_buffer
{
    $buffer = "";
}

sub get_out_buffer
{
    return $buffer;
}

1;

