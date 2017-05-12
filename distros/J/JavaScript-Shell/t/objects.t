use JavaScript::Shell;
use Data::Dumper;
use Test::More 'no_plan';

my $js = JavaScript::Shell->new();

$js->Set('person' => {});
$js->Set('person.fname' => 'Mamod');
$js->Set('person.lname' => 'Mehyar');

my $val = $js->get('eval' => qq!
    
    var fname = person.fname;
    var lname = person.lname;
    
    fname + ' ' + lname;
!)->value;

is($val,'Mamod Mehyar', "Person Object");


$js->Set('Arr' => [1,2,3,4]);

my $val2 = $js->get('Arr')->value(2);

is($val2,3, "Array Object");


$js->destroy();
