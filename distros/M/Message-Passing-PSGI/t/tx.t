use strict;
use warnings;
use Test::More 0.88;
use Scalar::Util qw/ refaddr /;
use JSON qw/ encode_json decode_json /;

BEGIN { use_ok 'Plack::App::Message::Passing' }

{
    package MyTestApp;
    use Moose;
    use Message::Passing::Output::Test;
    use Message::Passing::Input::Null;
    use Scalar::Util qw/ weaken /;

    extends 'Plack::App::Message::Passing';

    has '+input' => (
        default => sub {
            my $self = shift;
            weaken($self);
            Message::Passing::Input::Null->new(
                output_to => $self,
            );
        },
    );

    has '+output_to' => (
        default => sub {
            Message::Passing::Output::Test->new;
        },
    );

    no Moose;
}

my $app = MyTestApp->new(
    return_address => "tcp://127.0.0.1:5222",
    send_address => "tcp://127.0.0.1:5223",
);

ok $app;
is ref($app->to_app), 'CODE';

my $post_data = 'foobar';
open(my $reader, '<', \$post_data) or die $!;
my $errors = '';
open(my $error_writer, '>', \$errors) or die $!;
my $env = {
    'psgi.errors' => $error_writer,
    'psgi.input' => $reader,
    'psgi.nonblocking' => 1,
    'psgix.io' => 'bar',
    'psgi.streaming' => 'quux',
    'PATH_INFO' => '/',
};
my $env_addr = refaddr($env);

ok !exists($app->in_flight->{$env_addr});
my $res = $app->_handle_request($env);
my $response;
$res->(sub { $response = shift() });
ok exists($app->in_flight->{$env_addr});
is $app->output_to->message_count, 1;
my ($json) = $app->output_to->messages;
my $msg = decode_json($json);
is_deeply $msg, {
    'psgi.input' => $post_data,
    PATH_INFO => '/',
    'psgix.message.passing.clientid' => $env_addr,
    'psgix.message.passing.returnaddress' => 'tcp://127.0.0.1:5222',
};
my $send_res = [ 200, [], ['foo'] ];
ok !$response;
$app->consume(encode_json({
    clientid => $env_addr,
    response => $send_res,
    errors => 'SOME ERROR',
}));
ok $response;
is_deeply $response, $send_res;
is $errors, 'SOME ERROR';

done_testing;

