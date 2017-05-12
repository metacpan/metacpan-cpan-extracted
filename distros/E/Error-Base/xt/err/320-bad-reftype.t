use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;
use Error::Base::Cookbook;

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: ';
my $diag        = $base;
my @rv          ;
my $got         ;
my $self        ;
#~ my $want        ;

#----------------------------------------------------------------------------#
# SKIP OPTIONAL TEST

# Load non-core modules conditionally
BEGIN{
    my $diag   = 'load-test-trap';
    eval{
        require Test::Trap;         # Block eval on steroids
        Test::Trap->import (qw/ :default /);
    };
    my $module_loaded    = !$@;          # loaded if no error
                                            #   must be package variable
                                            #       to escape BEGIN block
    if ( $module_loaded ) {
        note($diag);
    }
    else {
        diag('Test::Trap required to execute this test script; skipping.');
        pass;
        done_testing(1);
        exit 0;
    };

}; ## BEGIN

#----------------------------------------------------------------------------#

# This script is once-through, for catching a single strange edge case.

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
#~    $Verbose++;

    
    my $t           ;
    my $code        ;
    my $leaveby     = 'die';
    my $want        = qr/bad reftype/;
    my $cranky      ;
    my $xtra        ;
    my @args        = ( '$in' => sub{return} );
    my $istr        = 'flim($in)flam';
    
    $tc++;
    $diag           = 'execute';
    @rv             = trap{ 
        my $err = Error::Base->new(@args); 
           $err->cuss($istr); 
        
    };
    pass( $diag );          # test didn't blow up
    
#~     diag('#=======#');
#~     diag(explain(\@rv));
#~     diag('#=======#');
    
    if    ( $leaveby eq 'die' and defined $want ) {
    $tc++;
        $diag           = 'should-die';
        $trap->did_die      ( $diag );
    $tc++;
        $diag           = 'die-like';
        $trap->die_like     ( $want, $diag );       # fail if !die
    $tc++;
        $diag           = 'die-quietly';
        $trap->quiet        ( $diag ) unless $cranky;
    }
    elsif ( $leaveby eq 'return-scalar' and defined $want ) {
        $diag           = 'should-return';
        $trap->did_return   ( $diag );
        $diag           = 'return-like';
        $trap->return_like  ( 0, $want, $diag );    # always returns aryref
        $diag           = 'return-quietly';
        $trap->quiet        ( $diag ) unless $cranky;
    } 
    elsif ( $leaveby eq 'return-object' and defined $want ) {
        $diag           = 'should-return';
        $trap->did_return   ( $diag );
        $diag           = 'return-object';
        $trap->return_isa_ok ( 0, 'Error::Base', $diag);
        $diag           = 'return-like';
        $self           = $rv[0];
        $got            = join qq{\n}, explain( $self );
        like( $got, $want, $diag );
        $diag           = 'return-quietly';
        $trap->quiet        ( $diag ) unless $cranky;
    }
    elsif ( $leaveby eq 'warn' and defined $want ) {
        $diag           = 'should-return';
        $trap->did_return   ( $diag );
        $diag           = 'warning-like';
        $trap->warn_like  ( 0, $want, $diag );      # always returns aryref
        $diag           = 'no-stdout';
        ok( !$trap->stdout, $diag );
    } 
    else {
        fail('Test script failure: unimplemented gimmick.');
    };
    
    if    ( $leaveby eq 'die' and defined $xtra ) {
        my $self    = $trap->die;
        eval { &$xtra($self) };
        $diag       = 'xtra-test-execute';
        fail($diag) if $@;
    };
    
    # Extra-verbose dump optional for test script debug.
    if ( $Verbose >= 1 ) {
        note( ''                            );
        $trap->diag_all;
        note( ''                            );
    };
    

#----------------------------------------------------------------------------#

END {
    done_testing($tc);
    exit 0;
}

#============================================================================#

sub words {                         # sloppy match these strings
    my @words   = @_;
    my $regex   = q{};
    
    for (@words) {
        $_      = lc $_;
        $regex  = $regex . $_ . '.*';
    };
    
    return qr/$regex/is;
};

