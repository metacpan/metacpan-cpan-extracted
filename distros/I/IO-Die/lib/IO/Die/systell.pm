package IO::Die;

use strict;

#----------------------------------------------------------------------
# CONVENIENCE
#

my $Fcntl_SEEK_CUR = 1;

#Note that, since we die() on error, this does NOT return "0 but true"
#as sysseek() does; instead it returns just a plain 0.
sub systell {
    my ( $NS, $fh ) = @_;

    #cf. perldoc -f tell
    return 0 + $NS->sysseek( $fh, 0, $Fcntl_SEEK_CUR );
}

1;
