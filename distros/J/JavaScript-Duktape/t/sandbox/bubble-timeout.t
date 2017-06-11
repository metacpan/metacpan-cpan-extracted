use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js  = JavaScript::Duktape->new();

my $duk = $js->duk;

my $start = time();
$js->set_timeout(3);

eval {
    $js->eval(q{
        function test (){
            try {
                while(1){ test() }
            } catch(e){ test() }
        }
        test();
    });
};

ok $@ =~ /timeout/;
ok ((time() - $start) >= 3);

done_testing();
