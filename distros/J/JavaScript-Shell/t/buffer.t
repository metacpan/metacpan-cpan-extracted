#!perl
use JavaScript::Shell;
use Data::Dumper;
use Test::More;

my $js = JavaScript::Shell->new();

my $bufferString = "this can be very long string";

$js->Set('Buffer' => sub {
    my $self = shift;
    my $args = shift;
    #return 11;
    return $self->buffer($self->getBuffer);
});


my $value = $js->get('eval' => qq!
    //send buffer
    function sendBuffer (){
        jshell.sendBuffer("$bufferString");
        return Buffer();
    }
    
    sendBuffer();
!)->value;

is($value, $bufferString);

$js->destroy();
done_testing(1);
