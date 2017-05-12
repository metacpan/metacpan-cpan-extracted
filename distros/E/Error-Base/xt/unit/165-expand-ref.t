use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#

my $foo         = 'foo';

#----------------------------------------------------------------------------#

my @td  = (
    {
        -case   => 'null',              # pass no args
        -args   => [
                ],
        -deep   => [
                    undef,
                ],
    },
    
    {
        -case   => 'foo',              # simple scalar
        -args   => [
                    'foo',
                ],
        -deep   => [
                    'foo',
                ],
    },
    
    {
        -case   => 'foo-ref',          # scalar reference
        -args   => [
                    \$foo,
                ],
        -deep   => [
                    'foo',
                ],
    },
    
    {
        -case   => 'aryref',           # array reference *joins*
        -args   => [
                    [ 1, 2, 3],
                ],
        -deep   => [
                    '1 2 3',
                ],
    },
    
    {
        -case   => 'hashref',           # hash reference *fatals*
        -args   => [
                    { foo => 'bar' },
                ],
        -die    => words(qw/ 
                    error base internal error bad reftype
                /),
    },
    
    {
        -case   => 'coderef',           # code reference *fatals*
        -args   => [
                    sub { return },
                ],
        -die    => words(qw/ 
                    error base internal error bad reftype
                /),
    },
    
#~     { -end    => 1 },   # # # # # # # END TESTING HERE # # # # # # # # #     
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: _expand_ref(): ';
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
        @rv = Error::Base::_expand_ref(@args); 
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



































































