use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#~ use Devel::Comments '###', ({ -file => 'debug.log' });                   #~

#----------------------------------------------------------------------------#

my @td  = (
    {
        -case   => 'null',
        -count  => 8,
    },
    
    {
        -case   => '(0)',
        -args   => [ -nest => 0 ],
        -count  => 8,
    },
    
    {
        -case   => '(-1)',
        -args   => [ -nest => -1 ],
        -count  => 9,
    },
    
    {
        -case   => '(-2)',
        -args   => [ -nest => -2 ],
        -count  => 10,
    },
    
    {
        -case   => '(+1)',
        -args   => [ -nest => 1 ],
        -count  => 7,
    },
    
    {
        -case   => '(+2)',
        -args   => [ -nest => 2 ],
        -count  => 6,
    },
    
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: -nest: ';
my $diag        = $base;
my @rv          ;
my $got         ;
my $want        ;

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
#~    $Verbose++;

for (@td) {
    $tc++;
    my $case        = $base . $_->{-case};
    
    ### $case
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
    my $count       = $t->{-count};
    
    $diag           = 'execute';
    @rv             = eval{ 
                        my $err = Error::Base->new(@args);
                        $err->cuss();
                        @rv     = $err;
                    };
    ### @rv
    pass( $diag );          # test didn't blow up
    note($@) if $@;         # did code under test blow up?
        
    if    ($die) {
        $diag           = 'should throw';
        $got            = $@;
        $want           = $die;
        like( $got, $want, $diag );
    }
    elsif ($want) {
        $diag           = 'return-like';
        $got            = join qq{\n}, @rv;
        like( $got, $want, $diag );
    } 
    elsif ( defined $count ) {
        $diag           = 'count';
        $got            = scalar @{ $rv[0]->{-frames} };
        $want           = $count;
        is( $got, $want, $diag );
    } 
    else {
        $diag           = 'return-is';
        $got            = join qq{\n}, @rv;
        $want           = join qq{\n}, @args;
        is( $got, $want, $diag );
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
        $regex  = $regex . $_ . '.*';
    };
    
    return qr/$regex/is;
};



































































