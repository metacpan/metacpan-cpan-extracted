use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#

my $prepend     = '@ Big Important Error: ';
my $madeup      = '@                      ';
my $indent      = '!--------------------! ';

my @td  = (
    {
        -case   => 'null',              # stringified normal return
        -want   => words(qw/ 
                    undefined error 
                    eval line prepend 
                    ____ line prepend 
                /),
    },
    
    {
#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 
        -case   => 'null-fuzz',         
        -fuzz   => words(qw/ 
                    bless 
                    frames 
                        eval undef file prepend line package main sub eval
                        bottom sub ___ 
                    lines
                        undefined error
                    error base
                /),
    },
    
    {
        -case   => 'prepend',               # prepend only
        -args   => [ 
                    -prepend    => $prepend,
                ],
        -fuzz   => words(
                    qw/ 
                        bless 
                        lines
                    /,
                    $prepend,
                    qw/ 
                        undefined error
                    /,
                    $madeup, 'line',
                    $madeup, 'line',
                    $madeup, 'line',
                    qw/
                        error base
                    /,                    
                ),
    },
    
    {
        -case   => 'prepend-indent',               # both
        -args   => [ 
                    -prepend    => $prepend,
                    -indent     => $indent,
                ],
        -fuzz   => words(
                    qw/ 
                        bless 
                        lines
                    /,
                    $prepend,
                    qw/ 
                        undefined error
                    /,
                    $indent, 'line',
                    $indent, 'line',
                    $indent, 'line',
                    qw/
                        error base
                    /,                    
                ),
    },
    
    {
        -case   => 'indent',               # indent only
        -args   => [ 
                    -indent     => $indent,
                ],
        -fuzz   => words(
                    qw/ 
                        bless 
                        bottom
                        sub ____
                        lines
                        undefined error
                    /,
                    $indent, 'line',
                    $indent, 'line',
                    $indent, 'line',
                    qw/
                        error base
                    /,                    
                ),
    },
    
    {
        -case   => 'prepend-base-both',     # emit error text, both ways
        -args   => [ 
                    'Bazfaz: ', 
                    -base       => 'Foobar error ', 
                    foo         => 'bar', 
                    -prepend    => $prepend,
                ],
        -fuzz   => words(
                    qw/ 
                        bless 
                        lines
                    /,
                    $prepend,
                    qw/ 
                        foobar error bazfaz in
                    /,
                    $madeup, 'line',
                    $madeup, 'line',
                    $madeup, 'line',
                    qw/
                        error base
                    /,                    
                ),
    },
    
    {
        -case   => 'quiet',             # emit error text, no backtrace
        -args   => [ 
                    'Bazfaz: ', 
                    -base       => 'Foobar error ', 
                    foo         => 'bar', 
                    -prepend    => $prepend,
                    -quiet  => 1, 
                ],
        -want   => words(
                    $prepend,
                    qw/
                        foobar error bazfaz
                    /
                ),
    },
    
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: -prepend: ';
my $diag        = $base;
my @rv          ;
my $got         ;
my $want        ;

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
    my @args        = eval{ @{ $t->{-args} } };
    my $die         = $t->{-die};
    my $want        = $t->{-want};
    my $deep        = $t->{-deep};
    my $fuzz        = $t->{-fuzz};
    
    $diag           = 'execute';
    @rv             = eval{ 
        Error::Base->cuss(@args); 
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
#~ use Devel::Comments '#####', ({ -file => 'debug.log' });

sub words {                         # sloppy match these strings
    my @words   = @_;
    my $regex   = q{};
    
    for (@words) {
        $_      = lc $_;
        $regex  = $regex . $_ . '.*';
    };
    ##### $regex
    return qr/$regex/is;
};



































































