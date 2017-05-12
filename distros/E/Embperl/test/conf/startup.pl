
BEGIN { 
    use lib qw{ . } ;
    use ExtUtils::testlib ;
    use Cwd ;

    $ENV{MOD_PERL} =~ m#/(\d+)\.(\d+)# ;
    $mp2 = 1 if ($1 == 2 || ($1 == 1 && $2 >= 99)) ;
    
    if ($mp2 && $ENV{PERL5LIB}) 
        {
        $ENV{PERL5LIB} =~ /^(.*)$/ ;
        eval 'use lib split (/:/, $1) ;' ;
        }
    my $dir = Cwd::fastcwd ;
    $dir =~ s#/#\\#g ;
    $dir =~ /^(.+)$/ ;
    $dir = $1 ; # untaint 
    $ENV{EMBPERL_SRC} =~ /^(.*?)$/;
    my $cwd       = $1 ; # untaint
    my $i = 0 ;
    foreach (@INC)
        {
        $INC[$i] = "$cwd/$_" if (/^\.?\/?blib/) ;
        $INC[$i] = "$cwd/$1" if (/^\Q$dir\E\\(blib\\.+)$/i) ;
        $INC[$i] =~ s#//#/#g ;
        $i++ ;
        }
   


    if (!$mp2)
        {
        require Apache ;
        require Apache::Registry ;
        }
    else
        {
	eval 'use Apache2' ;
#        require ModPerl::Registry ;
        }

    } ;


BEGIN 
    {
    $ENV{EMBPERL_SRC} =~ /^(.*?)$/;
    my $cwd       = $1 ;

    eval "use lib \"$cwd/eg/forms\"" ;

    if ($ENV{TEST_PRELOAD})
        {
        $Embperl::initparam{debug} = 0x7fffffff ;
        $Embperl::initparam{preloadfiles} = [
                { inputfile  => "$cwd/test/html/div.htm",  input_escmode => 7, debug => 0x7fffffff },
                { inputfile  => "$cwd/test/html/EmbperlObject/sub/eposubs.htm", input_escmode => 7, debug => 0x7fffffff }
                ] ;
        print "Preload initated\n" ;
        }

    }

# Bug#418067: apache2.2-mpm (at least) doesn't create a new process
# group with apache -X.  When exiting though, it SIGTERM's whatever
# the process group happens to be, wreaking havoc.  More importantly
# it causes 'make test' to exit with failure.  Hack around that here:
use POSIX ();
POSIX::setpgid(0,0);

use Embperl ;
use Embperl::Object ;

$ENV{EMBPERL_SRC} =~ /^(.*?)$/;
my $cwd       = $1 ;

require "$cwd/test/testapp.pl" ;

$cp = Embperl::Util::AddCompartment ('TEST') ;

$cp -> deny (':base_loop') ;
$testshare = "Shared Data" ;
$cp -> share ('$testshare') ;  

1 ;
