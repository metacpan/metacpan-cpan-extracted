use HTML::Widget;
use Test::MockObject;

my $w1 = HTML::Widget->new('widget1')->legend('widget1');
my $w2 = HTML::Widget->new('widget2');

$w1->element( 'Checkbox', 'checkbox1' )->label('Checkbox1');
$w1->element( 'Checkbox', 'checkbox2' )->label('Checkbox3');
$w1->element( 'Checkbox', 'checkbox3' )->label('Checkbox2');

$w1->element( 'Radio', 'radio' )->label('Radio1');
$w1->element( 'Radio', 'radio' )->label('Radio2');
$w1->element( 'Radio', 'radio' )->label('Radio3');

$w1->element( 'Textarea', 'textarea' )->label('Textarea');

$w1->element( 'Textfield', 'texfield' )->label('Textfield')
  ->comment('(Optional)');

$w1->element( 'Upload', 'upload' )->label('Upload');

$w1->element( 'Submit', 'submit' )->value('Submit');

$w1->constraint(
    'All',
    qw/checkbox1 checkbox2 checkbox3 radio1 radio2 radio3 textarea textfield upload submit/
)->message('Required');

my $f1 = $w1->process;
print "Example1:\n";
print $f1;

$w2->embed($w1);

my $f2 = $w2->process;
print "Example2:\n";
print $f2;

my $query = Test::MockObject->new;
my $data = { foo => 'bar' };
$query->mock( 'param',
    sub { $_[1] ? ( return $data->{ $_[1] } ) : ( keys %$data ) } );

my $f3 = $w2->process($query);
print "Example3:\n";
print $f3;
