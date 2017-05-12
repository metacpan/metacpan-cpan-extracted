#!perl
use JavaScript::Shell;
use Data::Dumper;
use Test::More 'no_plan';

my $js = JavaScript::Shell->new();

$js->onError(sub {
    my $self = shift;
    my $error = shift;
    
    is($error->{message}, 'Something went wrong', "Error Handle");
    
});

$js->eval(qq!
    throw('Something went wrong');
!);

$js->destroy();
