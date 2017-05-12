#!perl
use JavaScript::Shell;
use Data::Dumper;
use Test::More;

my $js = JavaScript::Shell->new();

my $ctx1 = $js->createContext();
my $ctx2 = $js->createContext();


my $val = $ctx1->get('eval' => qq!
    function counter (){
        var s = 1;
        while(1){
            s++;
            if (s === 1000) return s;
        }
    }
    
    counter();
    
!)->value;

ok($val == 1000, "Matching Number context1");

my $val2 = $ctx2->get('eval' => qq!
    1+2;
!)->value;

is($val2, 3, "Matching Number context2");

$js->destroy();
done_testing(2);
