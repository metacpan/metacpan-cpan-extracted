use lib '../lib';
use JSON::RPC::Dispatcher;

my $rpc = JSON::RPC::Dispatcher->new;

$rpc->register( 'ping', sub { return 'pong' } );
$rpc->register( 'echo', sub { return $_[0] } );

sub add_em {
    my @params = @_;
    my $sum = 0;
    $sum += $_ for @params;
    return $sum;
}

$rpc->register( 'sum', \&add_em );

# Want to do some fancy error handling? 
sub guess {
    my ($guess) = @_;
    if ($guess == 10) {
	return 'Correct!';
    }
    elsif ($guess > 10) {
	die [ 986, 'Too high.', $guess];
    }
    else {
	die [ 987, 'Too low.', $guess ];
    }
}

$rpc->register( 'guess', \&guess );

$rpc->to_app;

