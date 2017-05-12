use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#

my @td  = (
    {
        -case   => 'null',
        -want   => $QRFALSE,
    },
    
    {
        -case   => 'one',
        -args   => [ 0 ],
        -die    => words(qw/ internal error unpaired /),
    },
    
    {
        -case   => 'two',
        -args   => [ 0, 1 ],
    },
    
    {
        -case   => 'three',
        -args   => [ qw/ a b c / ],
        -die    => words(qw/ internal error unpaired /),
    },
    
    {
        -case   => 'four',
        -args   => [ qw/ a b c d / ],
    },
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: _paired(): ';
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
    my %t           = %{ $_ };
    my $case        = $base . $t{-case};
    
    note( "---- $case" );
    subtest $case => sub {
        
        my @args        = eval{ @{ $t{-args} } };
        my $die         = $t{-die};
        my $want        = $t{-want};
        
        $diag           = 'execute';
        @rv             = eval{ Error::Base::_paired(@args) };
        pass( $diag );          # test didn't blow up
#~         note($@) if $@;         # did code under test blow up?
        
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
}; ## for

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

__END__
