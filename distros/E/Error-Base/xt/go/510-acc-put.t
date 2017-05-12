use strict;
use warnings;

use Test::More;
use Storable (qw( dclone ));

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: acc-put: ';
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
        diag('Test::Trap required for this test script; skipping.');
        pass;
        done_testing(1);
        exit 0;
    };

}; ## BEGIN

#----------------------------------------------------------------------------#

my @td  = (
    
    {
        -case   => 'null',
        -code   => sub {
                    my $err = Error::Base->cuss( );
                    my $old = dclone($err);
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_base-null',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $err->put_base(  );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_base-foo',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $old->{-base} = 'foo';
                    $err->put_base( 'foo' );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_mesg-null',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $err->put_mesg(  );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_mesg-foo',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $old->{-mesg} = 'foo';
                    $err->put_mesg( 'foo' );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_mesg-foo-aryref',
        -code   => sub {
                    my $err = Error::Base->new( -mesg => 'foo' );
                    my $old = dclone($err);
                    $old->{-mesg} = [ 1, 2, 3];
                    $err->put_mesg( [ 1, 2, 3] );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_mesg-aryref-bar',
        -code   => sub {
                    my $err = Error::Base->new( -mesg => [ 1, 2, 3] );
                    my $old = dclone($err);
                    $old->{-mesg} = 'bar';
                    $err->put_mesg( 'bar' );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_quiet-null',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $err->put_quiet(  );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_quiet-0-1',
        -code   => sub {
                    my $err = Error::Base->new( -quiet => 0 );
                    my $old = dclone($err);
                    $old->{-quiet} = 1;
                    $err->put_quiet( 1 );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_quiet-1-0',
        -code   => sub {
                    my $err = Error::Base->new( -quiet => 1 );
                    my $old = dclone($err);
                    $old->{-quiet} = 0;
                    $err->put_quiet( 0 );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_nest-null',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $err->put_nest(  );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_nest-0-1',
        -code   => sub {
                    my $err = Error::Base->new( -nest => 0 );
                    my $old = dclone($err);
                    $old->{-nest} = 1;
                    $old->{-top} = $old->{-nest} + $Error::Base::BASETOP;
                    $err->put_nest( 1 );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'put_nest-1-0',
        -code   => sub {
                    my $err = Error::Base->new( -nest => 1 );
                    my $old = dclone($err);
                    $old->{-nest} = 0;
                    $old->{-top} = $old->{-nest} + $Error::Base::BASETOP;
                    $err->put_nest( 0 );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'pre-int-null',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $err->put_prepend(  );
                    $err->put_indent(  );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'pre-int-AAB',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $old->{-prepend} = 'AA';
                    $err->put_prepend( 'AA' );
                    $old->{-indent} = 'B';
                    $err->put_indent( 'B' );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'pre-int-AA-null',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $old->{-prepend} = 'AA';
                    $err->put_prepend( 'AA' );
                    $old->{-indent} = 'A ';
                    # $err->put_indent( 'B' );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'pre-int-null-B',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $old->{-prepend} = 'B';
                    # $err->put_prepend( 'AA' );
                    $old->{-indent} = 'B';
                    $err->put_indent( 'B' );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'pre-int-AA-empty',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $old->{-prepend} = 'AA';
                    $err->put_prepend( 'AA' );
                    $old->{-indent} = q{};
                    $err->put_indent( q{} );
                    return ( $err   => $old );
                },
    },
    
    {
        -case   => 'pre-int-empty-B',
        -code   => sub {
                    my $err = Error::Base->new( );
                    my $old = dclone($err);
                    $old->{-prepend} = q{};
                    $err->put_prepend( q{} );
                    $old->{-indent} = 'B';
                    $err->put_indent( 'B' );
                    return ( $err   => $old );
                },
    },
    
    { -end    => 1 },   # # # # # # # END TESTING HERE # # # # # # # # # 
    
); ## td

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
        is_deeply           ( $got, $want, $diag );
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
    
#~     # Extra-verbose dump optional for test script debug.
#~     if ( $Verbose >= 1 ) {
#~         note( ''                            );
#~         $trap->diag_all;
#~         note( ''                            );
#~     };
#~     
}; ## subtest

#----------------------------------------------------------------------------#

END {
    # Extra-verbose dump optional for test script debug.
    if ( $Verbose >= 1 ) {
        note( ''                            );
        $trap->diag_all;
        note( ''                            );
    };
    
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

