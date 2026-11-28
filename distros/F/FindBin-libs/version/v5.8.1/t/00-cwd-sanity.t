########################################################################
# housekeeping
########################################################################
package Testophile;
use strict;

use Test::More;

use Symbol      qw( qualify_to_ref );

require_ok qw( Cwd );
require_ok qw( File::Spec::Functions );

########################################################################
# sanity check whether Cwd has working subs
########################################################################

sub sanity
{
    my $handler = shift
    or return;

    eval
    {
        $handler->( '//' );
        $handler->( 'cwd' );
        1
    }
}

my $abs = Cwd->can( 'abs_path' );
my $rel = File::Spec::Functions->can( 'rel2abs' );

$abs || $rel
or BAIL_OUT "Cwd lacks 'abs_path' and F::S::F lacks 'rel2abs'";

sanity $abs
or 
sanity $rel
or
BAIL_OUT "Neither abs_path nor rel2abs handle '//' and 'cwd'";

my $ref = *{ qualify_to_ref 'abs_path', __PACKAGE__ };

undef &{ *$ref };

*{ $ref } = $abs || $rel;

__PACKAGE__->can( 'abs_path' )
or BAIL_OUT "Failed installing 'abs_path'";

pass 'Functinal abs_path installed';

done_testing


__END__

BEGIN
{
    # however... there have been complaints of 
    # places where abs_path does not work. 
    #
    # if abs_path fails on the working directory
    # then replace it with rel2abs and live with 
    # possibly slower, redundant directories.
    #
    # the abs_path '//' hack allows for testing 
    # broken abs_path on primitive systems that
    # cannot handle the rooted system being linked
    # back to itself.

    use Cwd qw( &cwd );

    my $abs = Cwd->can( 'abs_path'  )
    or die "Odd: Cwd cannot 'abs_path'\n";

    if
    (
        eval { $abs->( '//' );  $abs->( cwd ); 1 }
    )
    {
        # nothing more to do: abs_path works.
    }
    elsif
    (
        $abs = Cwd->can( 'rel2abs'  )
    )
    {
        # ok, we have a substitute
    }
    else
    {
        die "Cwd fails abs_path test && lacks 'rel2abs'\n";
    }

    my $ref = *{ qualify_to_ref 'abs_path', __PACKAGE__ };

    undef &{ *$ref };

    *{ $ref } = $abs;

}
