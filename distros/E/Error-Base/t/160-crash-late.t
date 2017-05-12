use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#

#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 

my @td  = (
    
    {
        -case   => 'base-late',
        -args   => [ 
                    -base   => 'a $zig b', 
                    -quiet  => 1, 
                    foo     => 'bar' 
                ],
        -merge  => [                     
                    '$zig'  => 'zag', 
                ],
        -die    => qr/a zag b$/,
    },
    
    {
        -case   => 'type-late',
        -args   => [ 
                    -type   => 'a $zig b', 
                    -quiet  => 1, 
                    foo     => 'bar' 
                ],
        -merge  => [                     
                    '$zig'  => 'zag', 
                ],
        -die    => qr/a zag b$/,
    },
    
    {
        -case   => 'pronto-late',
        -args   => [ 
                        'a $zig b', 
                    -quiet  => 1, 
                    foo     => 'bar' 
                ],
        -merge  => [                     
                    '$zig'  => 'zag', 
                ],
        -die    => qr/a zag b$/,
    },
    
    
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: crash-late: ';
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
    my @merge       = eval{ @{ $t->{-merge} } };
    my $die         = $t->{-die};
    my $want        = $t->{-want};
    my $deep        = $t->{-deep};
    my $fuzz        = $t->{-fuzz};
    
    $diag           = 'execute';
    @rv             = eval{ 
        my $self        = Error::Base->new(@args);
        $self->crash(@merge);
    };
    pass( $diag );          # test didn't blow up
#~     note($@) if $@;         # did code under test blow up?
    
    if    ($die) {
        $diag           = 'should-throw-string';
        $got            = lc "$@";
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



































































