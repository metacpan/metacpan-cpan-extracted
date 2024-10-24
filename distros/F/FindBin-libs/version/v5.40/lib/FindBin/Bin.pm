########################################################################
# housekeeping
########################################################################
package FindBin::Bin v0.1.0;
use v5.40;

use parent qw( Exporter );

use File::Spec::Functions   
qw
(
    canonpath
    catpath
    curdir
    rel2abs
    splitpath
);

BEGIN
{
    # recall that $0 is an lvalue!!
    # grab it quickly before it can change.
    # this will not change during execution, compute it once.
    #
    # note that $0 defaults to a file path, never a directory. 

    my $bin_from
    = $0  =~ m{^ (?: -e | - | interactive ) }x 
    ? curdir
    : ( splitpath $0 )[0,1]
    ;

    our $Bin    = canonpath rel2abs $bin_from;

    eval qq/sub Bin(){ '$Bin' }/;
}

########################################################################
# package variables & sanity checks
########################################################################

our @EXPORT_OK  = qw( $Bin Bin );

1
__END__

=head1 NAME

FindBin::Bin - Find the executin directory, exported via BIN()

=head1 SYNOSIS

    # if $0 is '-e' or '-' or 'interactive' then use the
    # working directory via File::Spec::Functions::curdir.
    # otherwise use vol+directory of $0.
    #
    # the path is extracted once at startup to avoid
    # issues with assignment to $0.

    # there you have it: $Bin is the path.

    use FindBin::Bin qw( $Bin );

    # sub call, sans $:
    # Bin is defines w/ no args and returns a constant string, 
    # it can be used as a sub or constant in your code. 
    
    use FindBin::Bin qw(  Bin );

    my $path = Bin;


    # Or, of course, both:

    use FindBin::Bin qw( $Bin Bin );

    say $Bin;
    /scratch/lembark/sandbox/Modules/Perl5/FindBin-libs

    say Bin;
    /scratch/lembark/sandbox/Modules/Perl5/FindBin-libs
