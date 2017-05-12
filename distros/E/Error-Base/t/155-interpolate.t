use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#
# CRAP

#~ my $err     = Error::Base->new(
#~                 '$foo'      => 'bar',
#~             );
#~ my $out     = $err->_late('-->$foo<--');
#~ 
#~ say STDERR q{};
#~ say STDERR '*]', $out, '[*';
#~ pass();
#~ 
#~ 
#~ done_testing(1);
#~ exit 0;

#----------------------------------------------------------------------------#

my $yokel   = 'Tom';

my @td  = (
    {
        -case   => 'null',
    },
    
    {
        -case   => 'instring-only',
        -istr   => q*yabba"qq||" dabba*,
        -want   => q*yabba"qq||" dabba*,
    },
    
    {
        -case   => 'instring-placeholder-no-value',
        -istr   => q*yabba($farmboy)dabba*,
        -want   => q*yabba($farmboy)dabba*,
        # interpolation suppressed entirely when no k/v pairs found in $self
    },
    
    {
        -case   => 'no-placeholder-some-value',
        -args   => [ 
                    '$farmboy'      => 'Hank',
                    '@farmgirls'    => [qw/ Ann Betty Cindy /],
                ],
        -istr   => q*yabba dabba doo*,
        -want   => q*yabba dabba doo*,
        # interpolation suppressed entirely when no sigil found in -istr
    },
    
    {
        -case   => 'scalar-value',
        -args   => [ 
                    '$farmboy'      => 'Hank',
                ],
        -istr   => q*yabba($farmboy)dabba*,
        -want   => q*yabba(Hank)dabba*,
    },
    
    {
        -case   => 'scalar-ref',
        -args   => [ 
                    '$farmhand'      => \$yokel,
                ],
        -istr   => q*yabba($farmhand)dabba*,
        -want   => q*yabba(Tom)dabba*,
    },
    
    {
        -case   => 'array-ref',
        -args   => [ 
                    '@farmgirls'    => [qw/ Ann Betty Cindy /],
                ],
        -istr   => q*yabba(@farmgirls)dabba*,
        -want   => q*yabba(Ann Betty Cindy)dabba*,
    },
    
    {
        -case   => 'array-slice',
        -args   => [ 
                    '@farmgirls'    => [qw/ Ann Betty Cindy /],
                ],
        -istr   => q*yabba(@farmgirls[ 0, 2 ])dabba*,
        -want   => q*yabba(Ann Cindy)dabba*,
    },
    
    {
        -case   => 'hash-slice',
        -args   => [ 
                    '%livestock'    => {qw/ dog Spot cow Bessie horse Stud/},
                ],
        -istr   => q*yabba(@livestock{ 'dog', 'cow' })dabba*,
        -want   => q*yabba(Spot Bessie)dabba*,
    },
    
    {
        -case   => 'two-placeholders-one-value',
        -args   => [ 
                    '@farmgirls'    => [qw/ Ann Betty Cindy /],
                ],
        -istr   => q*yabba($farmboy)($farmgirls[1])dabba*,
        -want   => q*yabba($farmboy)($farmgirls[1])dabba*,
        -warns  => 1,
        # raises internal warning and emits ::in
    },
    
    {
        -case   => 'the-whole-farm',
        -args   => [ 
                    '$farmboy'      => 'Hank',
                    '$farmhand'     => \$yokel,
                    '@farmgirls'    => [qw/ Ann Betty Cindy /],
                    '%livestock'    => {qw/ dog Spot cow Bessie horse Stud/},
                ],
        -istr   =>  q*Old MacDonald had *
                  . q*$farmhand, * 
                  . q*@livestock{ 'horse', 'cow' }, * 
                  . q*@farmgirls[ 2, 1 ], * 
                  . q*$farmboy, * 
                  . q* e-i-e-i-o*
                  ,
        -want   =>  q*Old MacDonald had Tom, Stud Bessie, Cindy Betty, Hank, *
                  . q* e-i-e-i-o*
                  ,
    },
    
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: interpolate: ';
my $diag        = $base;
my $rv          ;
my $got         ;
my $want        ;

#----------------------------------------------------------------------------#

#~ local $SIG{__WARN__}      = sub { note( $_[0]) };

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
#~    $Verbose++;

for (@td) {
    $tc++;
    my $case        = $base . $_->{-case};
    
    note( "---- $case" );
    if ($_->{-warns}) { 
        diag("$case: This case should emit a warning.");
    };
    
    subtest $case => sub { exck($_) };
}; ## for
    
sub exck {
    my $t           = shift;
    my @args        = eval{ @{ $t->{-args} } };
    my $istr        = $t->{-istr};
    my $die         = $t->{-die};
    my $want        = $t->{-want};
    
    $diag           = 'execute';
    $rv             = eval{ 
        my $err = Error::Base->new(@args); 
           $err->_late($istr); 
    };
    pass( $diag );          # test didn't blow up
    unless ($die) {
        fail($@) if $@;     # did code under test blow up?
    };
    
    if    ( defined $die) {
        $diag           = 'should-throw';
        $got            = $@;
        $want           = $die;
        like( $got, $want, $diag );
    }
    elsif ( defined $want ) {
        $diag           = 'return-exact';
        $got            = $rv;
        is( $got, $want, $diag );
    } 
    else {
        $diag           = 'return-undef';
        $got            = $rv;
        is( $got, undef, $diag );
    };

    # Extra-verbose dump optional for test script debug.
    if ( $Verbose >= 1 ) {
        note( 'rv: ', $rv                   );
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



































































