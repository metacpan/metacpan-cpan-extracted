use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use CGI;
use utf8;

use FormValidator::LazyWay;
use MyTestBase;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $cgi = new CGI( $block->param ) ;
    my $fv = FormValidator::LazyWay->new( { config => $block->config } );
    my $form = $fv->check( $cgi, $block->profile );
    is( $form->has_missing , $block->result );
}
__END__
=== dependancy
--- result chomp
1
--- param yaml
ab : 1 
bb : 
--- config yaml
lang : ja
rules:
    - Email
    - Number
setting :
    strict :
        ab:
            rule :
        bb:
            rule :
                - Email#email
--- profile eval
{
   required => [ qw/ab/ ],
   dependencies => {
    ab => {
        1 => [ 'bb' ] ,
    }
   }
}
=== dependancy
--- result eval 
0
--- param yaml
ab : 0
bb : 
--- config yaml
lang : ja
rules:
    - Email
    - Number
setting :
    strict :
        ab:
            rule :
        bb:
            rule :
                - Email#email
--- profile eval
{
   required => [ qw/ab/ ],
   dependencies => {
    ab => {
        1 => [ 'bb' ] ,
    }
   }
}

=== dependancy
--- result eval 
0
--- param yaml
ab: 1
bb: 1
--- config yaml
lang : ja
rules:
    - Email
    - Number
setting :
    strict :
        ab:
            rule :
        bb:
            rule :
                - Email#email
--- profile eval
{
   required => [ qw/ab/ ],
   dependencies => {
    ab => {
        1 => [ 'bb' ] ,
    }
   }
}

=== dependancy
--- result eval 
0
--- param yaml
ab: 1
aa: 1
bb: 1
--- config yaml
lang : ja
rules:
    - Email
    - Number
setting :
    strict :
        ab:
            rule :
        aa:
            rule :
                - Number#int
        bb:
            rule :
                - Email#email
--- profile eval
{
   required => [ qw/ab/ ],
   dependencies => {
     ab => {
       1 =>[ 'aa', 'bb' ],
     }
   }
}

=== dependancy
--- result eval 
0
--- param yaml
ab: 0
aa: 1
bb: 1
--- config yaml
lang : ja
rules:
    - Email
    - Number
setting :
    strict :
        ab:
            rule :
        aa:
            rule :
                - Number#int
        bb:
            rule :
                - Email#email
--- profile eval
{
   required => [ qw/ab/ ],
   dependencies => {
     ab => {
       1 =>[ 'aa', 'bb' ],
     }
   }
}

=== dependancy
--- result eval 
1
--- param yaml
ab: 1
aa: 
bb: 
--- config yaml
lang : ja
rules:
    - Email
    - Number
setting :
    strict :
        ab:
            rule :
        aa:
            rule :
                - Number#int
        bb:
            rule :
                - Email#email
--- profile eval
{
   required => [ qw/ab/ ],
   dependencies => {
     ab => {
       1 =>[ 'aa', 'bb' ],
     }
   }
}

=== dependancy
--- result eval 
1
--- param yaml
ab: 1
aa: 1
bb: 
--- config yaml
lang : ja
rules:
    - Email
    - Number
setting :
    strict :
        ab:
            rule :
        aa:
            rule :
                - Number#int
        bb:
            rule :
                - Email#email
--- profile eval
{
   required => [ qw/ab/ ],
   dependencies => {
     ab => {
       1 =>[ 'aa', 'bb' ],
     }
   }
}

=== dependancy
--- result eval 
1
--- param yaml
ab: 1
aa: 
bb: 1
--- config yaml
lang : ja
rules:
    - Email
    - Number
setting :
    strict :
        ab:
            rule :
        aa:
            rule :
                - Number#int
        bb:
            rule :
                - Email#email
--- profile eval
{
   required => [ qw/ab/ ],
   dependencies => {
     ab => {
       1 =>[ 'aa', 'bb' ],
     }
   }
}

