use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: load-optional: ';
my $diag        = $base;
my @rv          ;
my $got         ;
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
        -case   => 'sanity',
        -code   => sub{
            Error::Base->crash('Sanity check failed');  # die() with backtrace
        },
        -lby    => 'die',
        -want   => words(qw/ 
                    sanity check failed 
                    in main at line 
                    in eval at line 
                    ____    at line
                /),
    },
    
    {
        -case   => 'two-step',
        -code   => sub{
            my $err     = Error::Base->new('Foo');      # construct object first
              # yourcodehere(...);                  # ... do other stuff
            $err->crash;                                # as object method
        },
        -lby    => 'die',
        -want   => words(qw/ 
                    foo 
                    in main at line 
                    in eval at line 
                    ____    at line
                /),
    },
    
    {
        -case   => 'quiet',
        -code   => sub{
            my $err     = Error::Base->new(
                            'Foo error',                # odd arg is error text
                            -quiet    => 1,             # no backtrace
                            grink     => 'grunt',       # store somethings
                            puppy     => 'dog',         # your keys, no leading dash 
                        );
            $err->crash;
        },
        -lby    => 'die',
        -want   => qr/^Foo error$/,
        -xtra   => sub{
            my $self    = shift;
               $got     = $self->{grink} . $self->{puppy};
               $want    = 'gruntdog';
               $diag    = 'xtra-keys';
               is( $got, $want, $diag );
        },
    },
    
    {
        -case   => 'crank-same',
        -code   => sub{
            my $err     = Error::Base->new(
                            'Foo error',                # odd arg is error text
                            -quiet    => 1,             # no backtrace
                            grink     => 'grunt',       # store somethings
                            puppy     => 'dog',         # your keys, no leading dash 
                        );
            $err->crank;
        },
        -lby    => 'warn',
        -want   => qr/^Foo error$/,
        -xtra   => sub{
            my $self    = shift;
               $got     = $self->{grink} . $self->{puppy};
               $want    = 'gruntdog';
               $diag    = 'xtra-keys';
               is( $got, $want, $diag );
        },
    },
    
    {
        -case   => 'crank-me',
        -code   => sub{
            my $err = Error::Base->crank('Me!');        # also a constructor
        },
        -lby    => 'warn',
        -want   => words(qw/ 
                    me 
                    in main at line 
                    in eval at line 
                    ____    at line
                /),
    },
    
    {
        -case   => 'catch-crash',
        -code   => sub{
            eval{ Error::Base->crash( 'car', -foo => 'bar' ) }; 
            my $err     = $@ if $@;         # catch and examine the full object
                                            # actually though, test stringifies
        },
        -lby    => 'return-scalar',
        -want   => words(qw/ 
                    car
                    in main at line 
                    in eval at line 
                    ____    at line
                /),
    },
    
    {
        -case   => 'late',
        -code   => sub{
            my $err     = Error::Base->new(
                            -base       => 'File handler error:',
                            _openerr    => 'Couldn\t open $file for $op',
                        );
            {
                my $file = 'z00bie.xxx';    # uh-oh, variable out of scope...
                open my $fh, '<', $file
                    or $err->crash(
                        -type       => $err->{_openerr},
                        '$file'     => $file,
                        '$op'       => 'reading',
                    );                      # late interpolation to the rescue
            }
        },
        -lby    => 'die',
        -want   => words(qw/ 
                    file handler error couldn open z00bie xxx for reading
                    in main at line 
                    in eval at line 
                    ____    at line
                /),
    },
    
#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 
    
    
    
    
);

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
#~    $Verbose++;

for (@td) {
    last if $_->{-end};
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
    my $xtra        = $t->{-xtra};
    
    $diag           = 'execute';
    @rv             = trap{ 
        &$code;
    };
    pass( $diag );          # test didn't blow up
    
    if    ( $leaveby eq 'die' and defined $want ) {
        $diag           = 'should-die';
        $trap->did_die      ( $diag );
        $diag           = 'die-like';
        $trap->die_like     ( $want, $diag );       # fail if !die
        $diag           = 'die-quietly';
        $trap->quiet        ( $diag );
    }
    elsif ( $leaveby eq 'return-scalar' and defined $want ) {
        $diag           = 'should-return';
        $trap->did_return   ( $diag );
        $diag           = 'return-like';
        $trap->return_like  ( 0, $want, $diag );    # always returns aryref
        $diag           = 'return-quietly';
        $trap->quiet        ( $diag );
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

