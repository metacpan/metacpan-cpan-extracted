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
        -warn   => words(qw/ 
                    undefined error 
                    eval line crank 
                    ____ line crank 
                /),
    },
    
    {
        -case   => 'null-fuzz',         
        -fuzz   => words(qw/ 
                    bless 
                    frames 
                        eval undef file crank line package main sub eval
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
        -warn   => words(qw/
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
my $base        = 'Error-Base: crank(): ';
my $diag        = $base;
my @rv          ;
my $got         ;
my $want        ;
my $warning     ;

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
#~    $Verbose++;

for (@td) {
    $tc++;
    my $case        = $base . $_->{-case};
    
    note( "---- $case" );
    subtest $case => sub { exck($_) };
}; ## for
    
sub exck {
    my $t           = shift;
    my @args        = eval{ @{ $t->{-args} } };
    my $die         = $t->{-die};
    my $warn        = $t->{-warn};
    my $want        = $t->{-want};
    my $deep        = $t->{-deep};
    my $fuzz        = $t->{-fuzz};
    
    $diag           = 'execute';
    $warning        = undef;
    @rv             = eval{ 
        local $SIG{__WARN__}      = sub { $warning = $_[0] };
        Error::Base->crank(@args); 
    };
    pass( $diag );          # test didn't blow up
    note($@) if $@;         # did code under test blow up?
    
    if    ($die) {
        $diag           = 'should-throw-string';
        $got            = lc $@;
        $want           = $die;
        like( $got, $want, $diag );
    }
    elsif ($warn) {
        $diag           = 'should-warn-string';
        $got            = lc $warning;
        $want           = $warn;
        like( $got, $want, $diag );
    }
    elsif ($fuzz) {
        $diag           = 'should-warn-fuzzily';
        $got            = lc join qq{\n}, explain \$warning;
        $want           = $fuzz;
        like( $got, $want, $diag );
    }
    else {
        fail('Test script failure: unimplemented gimmick.');
    };

    # Extra-verbose dump optional for test script debug.
    if ( $Verbose >= 1 ) {
        note( 'explain: ', explain \$warning      );
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



































































