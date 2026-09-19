########################################################################
# housekeeping
########################################################################
package Testy;
use v5.40;
use FindBin::libs;
use FindBin::libs   qw( base=Dancer2 subdir=lib subonly export=dance_d scalar );
use FindBin::libs   qw( base=lib                        export=lib_d          );
use FindBin::libs   qw( base=t                          export=test_d  scalar );
use FindBin::libs   qw( base=.prove                     export=prove   scalar );
use autodie;

use File::Basename;
use Test::More;

use List::Util  qw( first );

use File::Spec::Functions
qw
(
    rel2abs
    catdir
    catpath
);

########################################################################
# package variables and sanity checks
########################################################################

my $base0   = basename $0;
my $dir0    = dirname  $0;

my $path
= do
{
    my $base    = basename $0 => qw( .t );
    my $sep     = substr $base, 0, 1;

    $base   =~ s{$sep}{/}gr
};

for( $path )
{
    -e      or BAIL_OUT "Non-existant: '$path'\n";
    -r _    or BAIL_OUT "Non-readable: '$path'\n";
}

my $test_d  = dirname $dir0; 
my $work_d  = dirname $test_d;

chdir $work_d   or BAIL_OUT "chdir $work_d, $!";

my $last_prove  = $ENV{ LAST_PROVE } // ( stat '.prove' )[9] // 0;

SKIP:
{
    ( stat $path )[9] > $last_prove
    or skip "File unchanged: $path", 1;

    $ENV{ PERL5LIB } = './lib';

    chomp( my @output = qx{ perl -wc $path 2>&1 } );

    if( $output[-1] =~ m{syntax \s OK $}x )
    {
        pass "Syntax OK: $base0";

        1 < @output
        and diag join "\n\t" => "\nWarnings:", @output;
    }
    else
    {
        fail "Fails compilation: $base0";
        diag join "\n\t" => "\nWarnings:", @output;
    }
}

done_testing

__END__

=head1 NAME

02-pm_t - generic unit test for perl modules.

=back
