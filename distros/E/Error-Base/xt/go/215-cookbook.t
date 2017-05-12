use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;
use Error::Base::Cookbook;

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base-Cookbook: ';
my $diag        = $base;
my @rv          ;
my $got         ;
my $self        ;
my $want        ;

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

my @td  = Error::Base::Cookbook::_get_test_data();

#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
#~    $Verbose++;

for (@td) {
    last if     $_->{-end};
    next unless $_->{-do};
    $tc++;
    my $case        = $base . $_->{-case};   
    note( "---- $case" );
    subtest $case => sub { exck($_) };
}; ## for
    
sub exck {
    my $t           = shift;
    my $code        = $t->{-code};
    my $leaveby     = $t->{-lby};
    my $want        = $t->{-want};
    my $cranky      = $t->{-cranky};
    my $xtra        = $t->{-xtra};
    
    $diag           = 'execute';
    @rv             = trap{ 
        &$code;
    };
    pass( $diag );          # test didn't blow up
    
#~     diag('#=======#');
#~     diag(explain(\@rv));
#~     diag('#=======#');
    
    if    ( $leaveby eq 'die' and defined $want ) {
        $diag           = 'should-die';
        $trap->did_die      ( $diag );
        $diag           = 'die-like';
        $trap->die_like     ( $want, $diag );       # fail if !die
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
    
}; ## subtest

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

