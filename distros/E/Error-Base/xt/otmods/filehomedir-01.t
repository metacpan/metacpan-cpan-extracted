use 5.010001;
use strict;
use warnings;

use Test::More;
use Test::Trap qw( :default );

use File::HomeDir;

#~ use Devel::Comments '###';                                  # debug only #~
#~ use Devel::Comments '#####', ({ -file => 'tr-debug.log' });              #~

#============================================================================#
# 
# Play around with File::HomeDir.  

#----------------------------------------------------------------------------#
# SETUP

my $unit        = 'File::HomeDir: ';
my $got         ;
my $want        ;
my $diag        = $unit;
my $tc          = 0;

my @test_data   = (
    {
        -diag       => 'methods',
        -args       => 'my_home',
        -return     => '',
    },
    
    {
        -diag       => 'methods',
        -args       => 'my_data',
        -return     => '',
    },
    
#~     {
#~         -diag       => 'methods',
#~         -args       => 'my_config',         # this dies
#~         -return     => '',
#~     },
    
    {
        -diag       => 'methods',
        -args       => 'my_dist_config',
        -return     => '',
    },
    
); ## test_data

#----------------------------------------------------------------------------#
# EXECUTE AND CHECK

for my $i (0..$#test_data) {
    # Extract the current test line and adjust the diagnostic message base.
    my $lineref     = $test_data[$i];
    my %line        = %$lineref;
    my $given       = $line{-args};
    my $base        = $unit . qq{<$i> } 
                    . q{|}
                    . $line{-diag}
                    . q{|}
                    . $given
                    . q{|}
                    ;
        
    # EXECUTE
    my $rv = trap{ 
        
        given ($given) {
            when (/my_home/)        { File::HomeDir->my_home }
            when (/my_data/)        { File::HomeDir->my_data }
            when (/my_config/)      { File::HomeDir->my_config }
            when (/my_dist_config/) { File::HomeDir->my_dist_config }
            default                 { die "Bad or no test argument $given."}
        }; ## given
    }; ## trap
##### $rv        
    # CHECK
    
#~     $trap->diag_all;                # Dumps the $trap object, TAP safe   #~
    
    $tc++;
    $diag   = $base . 'did_return';
    $trap->did_return($diag) or exit 1;
    
    # Don't even know if it's an error if this returns undef
#~     $tc++;
#~     $diag   = $base . 'return value';
#~     $got    = $trap->return(0);
#~     $want   = $line{-return};
#~     is(  $got, $want, $diag ) or exit 1;
    
    # Fall back to dumping results if prove -v
    $rv     = $rv // '';                # suppress warning uninitialized
    note("      Returned: $rv");
    
    $tc++;
    $diag   = $base . 'quiet';
    $trap->quiet($diag) or exit 1;      # no STDOUT or STDERR
        
    note(q{-});
}; ## for test_data

#----------------------------------------------------------------------------#
# TEARDOWN

END {
    done_testing($tc);                  # declare plan after testing
#~     done_testing();                  # declare no plan at all
}

#============================================================================#
