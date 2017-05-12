BEGIN { 
    use lib qw{ . } ;
    use ExtUtils::testlib ;
    use Cwd ;
    
    if ($EPSESSIONCLASS = $ENV{EMBPERL_SESSION_CLASS})
        {
        eval " use Apache\:\:Session; " ;
        die $@ if ($@) ;
        eval " use Apache\:\:Session\:\:$EPSESSIONCLASS; " ;
        }

    my $cwd       = $ENV{EMBPERL_SRC} ;
    my $i = 0 ;
    foreach (@INC)
        {
        $INC[$i] = "$cwd/$_" if (/^(\.\/)?blib/) ;
        $i++ ;
        }
   

    } ;


use Apache ;
use Apache::Registry ;
use HTML::Embperl ;

$cp = HTML::Embperl::AddCompartment ('TEST') ;

$cp -> deny (':base_loop') ;
$testshare = "Shared Data" ;
$cp -> share ('$testshare') ;  

1 ;
