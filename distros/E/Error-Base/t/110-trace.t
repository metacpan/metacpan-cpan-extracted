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
        -want   => words(qw/ 
                    in exck 
                    in anon 
                    in subtest
                    in ___ line trace 
                /),
    },
    
    {
        -case   => 'top-0',
        -args   => [ {}, -top => 0 ],   # dummy $self
        -want   => words(qw/ 
                    in eval 
                    in exck 
                    in anon 
                    in subtest
                    in ___ line trace 
                /),
    },
    
    {
        -case   => 'top-1',
        -args   => [ {}, -top => 1 ],   # dummy $self
        -want   => words(qw/ 
                    in exck 
                    in anon 
                    in subtest
                    in ___ line trace 
                /),
    },
    
    {
        -case   => 'top-2',
        -args   => [ {}, -top => 2 ],   # dummy $self
        -want   => words(qw/ 
                    in anon 
                    in subtest
                    in ___ line trace 
                /),
    },
    
    {
        -case   => 'top-4',
        -args   => [ {}, -top => 4 ],   # dummy $self
        -want   => words(qw/ 
                    in subtest
                    in ___ line trace 
                /),
    },
    
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: _trace(): ';
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
    @rv             = eval{ Error::Base::_trace(@args) };
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



































































