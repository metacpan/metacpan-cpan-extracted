use lib "e:/shell/lib";
use JavaScript::Shell;
use Data::Dumper;
my $js = JavaScript::Shell->new();

my $bufferString = "this can be very long string";

$js->Set('bb' => sub {
    my $self = shift;
    my $args = shift;
    print Dumper $args;
    return $self->buffer($self->{buffer});
});

my $value = $js->get('eval' => qq!
    
    function getBuffer (){
        jshell.sendBuffer("$bufferString");
        return bb();
    }
    
    getBuffer();
!)->value();

print Dumper $value;
