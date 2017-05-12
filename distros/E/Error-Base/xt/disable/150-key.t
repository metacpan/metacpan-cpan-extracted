use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#
#
# The -key param was removed long ago; dunno why this was left in t/go. 
# Oddly enough, the test passes; so the test script itself is broken. 
#       DO NOT USE
#
#----------------------------------------------------------------------------#

my $err     = Error::Base->new(
                -base       => '',
                _error1     => ' 1st error',
                _error2     => ' 2nd error',
            );

my @td  = (
    {
        -case   => 'key-fuzz',          # key only
        -args   => [ 
                    foo     => 'bar',
                    -key    => '_error1', 
                ],
        -fuzz   => words(qw/ 
                    bless 
                        lines 1st error
                    error base
                /),
    },
    
    {
#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 
        -case   => 'err-fuzz',          # emit error text
        -args   => [ 
                    'Foobar error', 
                    foo     => 'bar', 
                    -key    => '_error1', 
                ],
        -fuzz   => words(qw/ 
                    bless 
                        lines foobar error 1st error
                    error base
                /),
    },
    
    {
        -case   => 'text-fuzz',         # emit error text, named arg
        -args   => [ 
                    -base   => 'Foobar error ', 
                    foo     => 'bar', 
                    -key    => '_error1', 
                ],
        -fuzz   => words(qw/ 
                    bless 
                        lines foobar error
                    error base
                /),
    },
    
    {
        -case   => 'text-both-fuzz',    # emit error text, both ways
        -args   => [ 
                    'Bazfaz: ', 
                    -base   => 'Foobar error ', 
                    foo     => 'bar', 
                    -key    => '_error1', 
                ],
        -fuzz   => words(qw/ 
                    bless 
                        lines foobar error bazfaz in
                    error base
                /),
    },
    
    {
        -case   => 'text-both',         # emit error text, stringified normal
        -args   => [ 
                    'Bazfaz: ', 
                    -base   => 'Foobar error ', 
                    foo     => 'bar', 
                    -key    => '_error1', 
                ],
        -want   => words(qw/ 
                    foobar error bazfaz
                    eval line key 
                    ____ line key
                /),
    },
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: -key: ';
my $diag        = $base;
my @rv          ;
my $got         ;
my $want        ;

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
   $Verbose++;

for (@td) {
    last if $_->{-end};
    $tc++;
    my $case        = $base . $_->{-case};
    
    note( "---- $case" );
    subtest $case => sub { exck($_) };
}; ## for
    
sub exck {
    my $t           = shift;
    my @args        = eval{ @{ $t->{-args} } };
    my $die         = $t->{-die};
    my $want        = $t->{-want};
    my $deep        = $t->{-deep};
    my $fuzz        = $t->{-fuzz};
    
    $diag           = 'execute';
    @rv             = eval{ 
        $err->cuss(@args); 
    };
    pass( $diag );          # test didn't blow up
    note($@) if $@;         # did code under test blow up?
    
    if    ($die) {
        $diag           = 'should throw';
        $got            = $@;
        $want           = $die;
        like( $got, $want, $diag );
    }
    elsif ($want) {
        $diag           = 'return-words';
        $got            = lc join qq{\n}, @rv;
        like( $got, $want, $diag );
    } 
    elsif ($deep) {
        $diag           = 'return-deeply';
        $got            = \@rv;
        $want           = $deep;
        is_deeply( $got, $want, $diag );
    }
    elsif ($fuzz) {
        $diag           = 'return-fuzzily';
        $got            = join qq{\n}, explain \@rv;
        $want           = $fuzz;
        like( $got, $want, $diag );
    }
    else {
        fail('Test script failure: unimplemented gimmick.');
    };

    # Extra-verbose dump optional for test script debug.
    if ( $Verbose >= 1 ) {
        note( 'explain: ', explain \@rv     );
        note( ''                            );
    };
    
}; ## subtest

#----------------------------------------------------------------------------#

done_testing($tc);
exit 0;

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



































































