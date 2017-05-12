use strict;
use warnings;
use Plack::Runner;
use Plack::App::Message::Passing;

my $app = Plack::App::Message::Passing->new(
    return_address => "tcp://127.0.0.1:5555",
    send_address => "tcp://127.0.0.1:5556",
)->to_app;

use Twiggy::Server;
$ENV{PLACK_SERVER} = "Twiggy";

unless (caller()) {
    my $runner = Plack::Runner->new;
    $runner->parse_options(@ARGV);
    $runner->run($app);
}

no warnings 'void';
$app;

