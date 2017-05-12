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
        -want   => words(qw/ 
                    undefined error 
                        throw line cuss 
                        eval line eval
                        exck line cuss
                            string eval throw
                /),
    },
    
    {
#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 
        -case   => 'null-fuzz',         
        -fuzz   => words(qw/ 
                    bless 
                    frames 
                        sub throw 
                        sub eval
                        sub exck
                        bottom sub ____ 
                    lines
                        undefined error
                        string eval
                    error base
                /),
    },
    
    {
        -case   => 'foo-fuzz',          # preserve private attribute
        -args   => [ foo => 'bar' ],
        -fuzz   => words(qw/ 
                    bless 
                        foo bar
                    error base
                /),
    },
    
    {
        -case   => 'text-fuzz',         # emit error text
        -args   => [ 'Foobar error', foo => 'bar' ],
        -fuzz   => words(qw/ 
                    bless 
                        lines foobar error
                    error base
                /),
    },
    
    {
        -case   => 'text-fuzz',         # emit error text, named arg
        -args   => [ -base => 'Foobar error ', foo => 'bar' ],
        -fuzz   => words(qw/ 
                    bless 
                        lines foobar error
                    error base
                /),
    },
    
    {
        -case   => 'text-both-fuzz',    # emit error text, both ways
        -args   => [ 'Bazfaz: ', -base => 'Foobar error ', foo => 'bar' ],
        -fuzz   => words(qw/ 
                    bless 
                        lines foobar error bazfaz in
                    error base
                /),
    },
    
    {
        -case   => 'text-both',         # emit error text, stringified normal
        -args   => [ 'Bazfaz: ', -base => 'Foobar error ', foo => 'bar' ],
        -want   => words(qw/ 
                    foobar error bazfaz
                    main throw line cuss
                    exck line cuss
                        string eval throw
                /),
    },
    
    {
        -case   => 'nest-2-fuzz',        # mess with -nest
        -args   => [ 
                    'Bazfaz: ',
                    -nest    => 2, 
                    -base   => 'Foobar error ', 
                    foo     => 'bar', 
                ],
        -fuzz   => words(qw/ 
                    lines
                        foobar error bazfaz
                        exck line cuss
                            string eval throw
                        ____ line
                    nest 2
                    foo bar
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
        -want   => words(qw/
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
my $base        = 'Error-Base: string-cuss: ';
my $diag        = $base;
my @rv          ;
my $got         ;
my $want        ;

sub throw {
    my @args    = @_;
    return Error::Base->cuss(@args);
};

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
    @rv             = eval '    throw(@args);    ';     # string eval
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



































































