use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

my $js = JavaScript::Duktape->new();
my $vm = $js->vm;

$vm->push_string("Should Stay");

$vm->push_function( sub {
    my $self = shift;
    $self->dump();
    my $str = $self->require_string(0);

    $self->push_string("shit");
    $self->push_value_stack({});
    $vm->dump();

    return 1;
}, 1);

$vm->push_string("firstArg");
$vm->push_int(1);
$vm->call(2);

my $var = "";
open my $fh, '+>', undef;

$vm->dump("ST");
seek $fh,0,0;
my $document = do {
    local $/ = undef;
    <$fh>;
};
