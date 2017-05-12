use strict;
use warnings;

use Test::More;

use Error::Base;

#~ use Devel::Comments '###', ({ -file => 'debug.log' });                   #~

#----------------------------------------------------------------------------#
# This just to test the new feature as shown in E::B POD. 

my $tc          ;
my $base        = 'Error-Base: mesg-aryref: ';
my $diag        = $base . 'like';
my $got         ;
my $want        ;
my $err         = Error::Base->new();

    my $foo     = 'bar';
    $err->cuss(
            -mesg => [ 'Cannot find', $foo, q{.} ],
    );                                  # emits 'Cannot find bar .'

### $err
    
    $tc++;
    $got        = "$err";
    $want       = qr/Cannot find bar \./;
    like( $got, $want, $diag );
    
    
    
    
    done_testing($tc);
    exit 0;

#============================================================================#
