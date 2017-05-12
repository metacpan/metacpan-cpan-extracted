use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: acc-get: ';
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

my @td  = (
    
    {
        -case   => 'get_base-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-base}   => $err->get_base(),
                    );
                },
    },
    
    {
        -case   => 'get_base-foo',
        -code   => sub {
                    my $err = Error::Base->cuss( -base => 'foo' );
                    return (
                        $err->{-base}   => $err->get_base(),
                    );
                },
    },
    
    {
        -case   => 'get_type-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-type}   => $err->get_type(),
                    );
                },
    },
    
    {
        -case   => 'get_type-foo',
        -code   => sub {
                    my $err = Error::Base->cuss( -type => 'foo' );
                    return (
                        $err->{-type}   => $err->get_type(),
                    );
                },
    },
    
    {
        -case   => 'get_mesg-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-mesg}   => $err->get_mesg(),
                    );
                },
    },
    
    {
        -case   => 'get_mesg-foo',
        -code   => sub {
                    my $err = Error::Base->cuss( -mesg => 'foo' );
                    return (
                        $err->{-mesg}   => $err->get_mesg(),
                    );
                },
    },
    
    {
        -case   => 'get_mesg-aryref',
        -code   => sub {
                    my $err = Error::Base->cuss( -mesg => [ 1, 2, 3 ] );
                    return (
                        $err->{-mesg}   => $err->get_mesg(),
                    );
                },
    },
    
    {
        -case   => 'get_quiet-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-quiet}   => $err->get_quiet(),
                    );
                },
    },
    
    {
        -case   => 'get_quiet-1',
        -code   => sub {
                    my $err = Error::Base->cuss( -quiet => 1 );
                    return (
                        $err->{-quiet}   => $err->get_quiet(),
                    );
                },
    },
    
    {
        -case   => 'get_nest-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-nest}   => $err->get_nest(),
                    );
                },
    },
    
    {
        -case   => 'get_nest-1',
        -code   => sub {
                    my $err = Error::Base->cuss( -nest => 1 );
                    return (
                        $err->{-nest}   => $err->get_nest(),
                    );
                },
    },
    
    {
        -case   => 'get_prepend-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-prepend}   => $err->get_prepend(),
                    );
                },
    },
    
    {
        -case   => 'get_prepend-foo',
        -code   => sub {
                    my $err = Error::Base->cuss( -prepend => 'foo' );
                    return (
                        $err->{-prepend}   => $err->get_prepend(),
                    );
                },
    },
    
    {
        -case   => 'get_indent-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-indent}   => $err->get_indent(),
                    );
                },
    },
    
    {
        -case   => 'get_indent-foo',
        -code   => sub {
                    my $err = Error::Base->cuss( -indent => 'foo' );
                    return (
                        $err->{-indent}   => $err->get_indent(),
                    );
                },
    },
    
    {
        -case   => 'get_all-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-all}   => $err->get_all(),
                    );
                },
    },
    
    {
        -case   => 'get_all-stuff',
        -code   => sub {
                    my $err = Error::Base->cuss( 
                                    -base   => 'foo',
                                    -type   => 'bar',
                                    -mesg   => 'baz', 
                                );
                    return (
                        $err->{-all}   => $err->get_all(),
                    );
                },
    },
    
    {
        -case   => 'get_lines-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-lines}   => $err->get_lines(),
                    );
                },
    },
    
    {
        -case   => 'get_lines-stuff',
        -code   => sub {
                    my $err = Error::Base->cuss( 
                                    -base   => 'foo',
                                    -type   => 'bar',
                                    -mesg   => 'baz', 
                                );
                    return (
                        $err->{-lines}   => $err->get_lines(),
                    );
                },
    },
    
    {
        -case   => 'get_frames-null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    return (
                        $err->{-frames}   => $err->get_frames(),
                    );
                },
    },
    
    {
        -case   => 'get_frames-stuff',
        -code   => sub {
                    my $err = Error::Base->cuss( 
                                    -base   => 'foo',
                                    -type   => 'bar',
                                    -mesg   => 'baz', 
                                );
                    return (
                        $err->{-frames}   => $err->get_frames(),
                    );
                },
    },
    
); ## td

#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
#~    $Verbose++;

for (@td) {
    last if     $_->{-end};
#~     next unless $_->{-do};
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


        $diag           = 'should-return';
        $trap->did_return   ( $diag );
        $diag           = 'return-compare';
        $got            = $trap->return(0);
        $want           = $trap->return(1);
        is                  ( $got, $want, $diag );
        $diag           = 'return-quietly';
        $trap->quiet        ( $diag ) unless $cranky;
    
#~     if    ( $leaveby eq 'die' and defined $want ) {
#~         $diag           = 'should-die';
#~         $trap->did_die      ( $diag );
#~         $diag           = 'die-like';
#~         $trap->die_like     ( $want, $diag );       # fail if !die
#~         $diag           = 'die-quietly';
#~         $trap->quiet        ( $diag ) unless $cranky;
#~     }
#~     elsif ( $leaveby eq 'return-scalar' and defined $want ) {
#~         $diag           = 'should-return';
#~         $trap->did_return   ( $diag );
#~         $diag           = 'return-like';
#~         $trap->return_like  ( 0, $want, $diag );    # always returns aryref
#~         $diag           = 'return-quietly';
#~         $trap->quiet        ( $diag ) unless $cranky;
#~     } 
#~     elsif ( $leaveby eq 'return-object' and defined $want ) {
#~         $diag           = 'should-return';
#~         $trap->did_return   ( $diag );
#~         $diag           = 'return-object';
#~         $trap->return_isa_ok ( 0, 'Error::Base', $diag);
#~         $diag           = 'return-like';
#~         $self           = $rv[0];
#~         $got            = join qq{\n}, explain( $self );
#~         like( $got, $want, $diag );
#~         $diag           = 'return-quietly';
#~         $trap->quiet        ( $diag ) unless $cranky;
#~     }
#~     elsif ( $leaveby eq 'warn' and defined $want ) {
#~         
#~         $diag           = 'should-return';
#~         $trap->did_return   ( $diag );
#~         $diag           = 'warning-like';
#~         $trap->warn_like  ( 0, $want, $diag );      # always returns aryref
#~         $diag           = 'no-stdout';
#~         ok( !$trap->stdout, $diag );
#~     } 
#~     else {
#~         fail('Test script failure: unimplemented gimmick.');
#~     };
    
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

