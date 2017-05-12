use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#

my @td  = (
    {
        -case   => 'null',              # stringified normal return
        -die    => words(qw/ 
                    undefined error 
                    eval line crash 
                    ____ line crash 
                /),
    },
    
    {
#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 
        -case   => 'null-fuzz',         
        -fuzz   => words(qw/ 
                    bless 
                    frames 
                        eval undef file crash line package main sub eval
                        bottom sub ___ 
                    lines
                        undefined error
                    error base
                /),
    },
    
    {
        -case   => 'quiet',             # emit error text, no backtrace
        -args   => [ 
                    'Bazfaz: ',
                    -quiet  => 1, 
                    -base   => 'Foobar error ', 
                    foo     => 'bar', 
                ],
        -die    => words(qw/
                    foobar error bazfaz
                /),
    },
    
    {
        -case   => 'quiet-fuzz',        # verify no backtrace
        -args   => [ 
                    'Bazfaz: ',
                    -quiet  => 1, 
                    -base   => 'Foobar error ', 
                    foo     => 'bar', 
                ],
        -fuzz   => words(qw/ 
                    lines
                        foobar error bazfaz
                    quiet
                /),
    },
    
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: crash(): ';
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
        Error::Base->crash(@args); 
    };
    pass( $diag );          # test didn't blow up
#~     note($@) if $@;         # did code under test blow up?
    
    if    ($die) {
        $diag           = 'should-throw-string';
        $got            = lc $@;
        $want           = $die;
        like( $got, $want, $diag );
    }
    elsif ($fuzz) {
        $diag           = 'should-throw-fuzzily';
        $got            = join qq{\n}, explain \$@;
        $want           = $fuzz;
        like( $got, $want, $diag );
    }
    else {
        fail('Test script failure: unimplemented gimmick.');
    };

    # Extra-verbose dump optional for test script debug.
    if ( $Verbose >= 1 ) {
        note( 'explain: ', explain \$@      );
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



































































