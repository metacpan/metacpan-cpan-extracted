#!perl
use JavaScript::Shell;
use Data::Dumper;
use Test::More 'no_plan';

my $js = JavaScript::Shell->new();

$js->eval(qq!
    function test (){
        return 999;
    }
!);

my $result = $js->get('test');
is  ($result->value, 999, "Match Simple Return");


$js->Set(numbers => [ 2, 4, 6, 8, 10, 12 ]);
$js->Set(start => 1);
$js->eval(q{
    function add_next() {
        var n;
        if(n = numbers.shift()) {
            start = start + n;
            return start;
        } else {
            return;
        }
    }
});

#my $pp = $js->get('add_next');
my $expected = [3,7,13,21,31,43];
my $i = 0;
while (my $num = $js->get('add_next')->value){
    is($num, $expected->[$i++], "Matching Number $i");
}


$js->destroy();


