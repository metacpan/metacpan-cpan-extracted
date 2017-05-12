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
                    eval line new 
                    ____ line new 
                /),
    },
    
    {
        -case   => 'null-fuzz',         
        -fuzz   => words(qw/ 
                    bless 
                    frames 
                        eval undef file new line package main sub eval
                        bottom sub ___ 
                    lines
                        undefined error
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
        -case   => 'pronto-fuzz',         # emit error text
        -args   => [ 'Foobar error', foo => 'bar' ],
        -fuzz   => words(qw/ 
                    bless 
                        lines foobar error
                    error base
                /),
    },
    
    {
#~         -end    => 1,   # # # # # # # END TESTING HERE # # # # # # # # # 
        -case   => 'base-fuzz',         # emit error text, named arg
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
                    eval line new 
                    ____ line new
                /),
    },
    
    {
        -case   => 'nest-0-fuzz',        # mess with -nest
        -args   => [ 
                    'Bazfaz: ',
                    -nest    => -2, 
                    -base   => 'Foobar error ', 
                    foo     => 'bar', 
                ],
        -fuzz   => words(qw/ 
                    lines
                        foobar error bazfaz
                        error base fuss lib error base
                        error base cuss lib error base
                    eval line new 
                    exck line new
                    top 0
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
my $base        = 'Error-Base: new(): ';
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
        my $self        = Error::Base->new(@args);
        $self->cuss;
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



































































