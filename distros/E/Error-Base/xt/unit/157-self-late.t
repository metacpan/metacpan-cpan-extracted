use strict;
use warnings;

use Test::More;

use Error::Base;
my $QRTRUE       = $Error::Base::QRTRUE    ;
my $QRFALSE      = $Error::Base::QRFALSE   ;

#----------------------------------------------------------------------------#

my $yokel   = 'Tom';

my @td  = (
    
    {
        -case   => 'array-ref',
        -args   => [ 
                    '$trigger'      => 1,
                    '_farmgirls'    => [qw/ Ann Betty Cindy /],
                ],
        -istr   => q*yabba(@{ $self->{_farmgirls} })dabba*,
        -want   => q*yabba(Ann Betty Cindy)dabba*,
    },
    
    {
        -case   => 'array-slice',
        -args   => [ 
                    '$trigger'      => 1,
                    '_farmgirls'    => [qw/ Ann Betty Cindy /],
                ],
        -istr   => q*yabba(@{ $self->{_farmgirls} }[0,2])dabba*,
        -want   => q*yabba(Ann Cindy)dabba*,
    },
    
    {
        -case   => 'the-whole-farm',
        -args   => [ 
                    '$trigger'      => 1,
                    '_farmboy'      => 'Hank',
                    '_farmhand'     => \$yokel,
                    '_farmgirls'    => [qw/ Ann Betty Cindy /],
                    '_livestock'    => {qw/ dog Spot cow Bessie horse Stud/},
                ],
        -istr   =>  q*Old MacDonald had *
                  . q*${ $self->{ _farmhand  } }, * 
                  . q*@{ $self->{ _livestock } }{ 'horse', 'cow' }, * 
                  . q*@{ $self->{ _farmgirls } }[ 2, 1 ], * 
                  .    q*$self->{ _farmboy   }, * 
                  . q* e-i-e-i-o*
                  ,
        -want   =>  q*Old MacDonald had Tom, Stud Bessie, Cindy Betty, Hank, *
                  . q* e-i-e-i-o*
                  ,
    },
    
    
);

#----------------------------------------------------------------------------#

my $tc          ;
my $base        = 'Error-Base: self-late: ';
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



































































