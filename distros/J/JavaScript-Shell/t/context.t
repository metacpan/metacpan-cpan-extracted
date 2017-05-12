use JavaScript::Shell;
use Data::Dumper;
use Test::More tests => 6;

my $js = JavaScript::Shell->new();

my $ctx = $js->createContext({
    test => 'first context'
});

my $ctx2 = $js->createContext({
    test => 'second context'
});

is($ctx->get('test')->value, 'first context', 'First Context');
is($ctx2->get('test')->value, 'second context', 'Second Context');

$ctx->Set('runfun' => sub {
    my $js = shift;
    my $args = shift;
    return 'first context'
});


is($ctx->get('runfun')->value, 'first context', 'Function in First Context');
is($ctx2->get('runfun')->value, undef, 'undefined function in Second Context');


$ctx2->Set('testFun' => sub {
    my $js = shift;
    my $args = shift;
    my $name = $args->[0];
    
    ##nested
    $js->Set('Last' => 'Mehyar');
    
    is($name, 'Mamod', 'Test inside Function');
});

$ctx2->call('testFun','Mamod');
is($ctx2->get('Last')->value, 'Mehyar', 'Value set inside context function');

$js->destroy();
