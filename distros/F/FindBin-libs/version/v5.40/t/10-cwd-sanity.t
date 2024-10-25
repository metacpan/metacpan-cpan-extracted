########################################################################
# housekeeping
########################################################################
package Testophile;

use Test::More;

use Symbol      qw( qualify_to_ref );

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


my $cur = File::Spec::Functions->can( 'curdir'  )
or BAIL_OUT q{F::S::F  lacks 'curdir'};

my $rel = File::Spec::Functions->can( 'rel2abs' )
or BAIL_OUT q{F::S::F  lacks 'rel2abs'};

my $cwd = $cur->()
or BAIL_OUT q{F::S::F::curdir returns empty.};

note "Working dir:  '$cwd'";

my $abs = $rel->( $cwd )
or BAIL_OUT q{F::S::F::rel2abs returns empty for '$cwd'.};

note "Abs path:     '$abs'";

-e $abs
or BAIL_OUT q{F::S::F::rel2abs returns non-existant '$cwd'.};

pass 'Usable current directory handler.';

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
