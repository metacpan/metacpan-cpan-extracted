package Plack::Handler::Message::Passing;
use Moose;
use AnyEvent;
use Message::Passing::Output::ZeroMQ;
use Message::Passing::Input::ZeroMQ;
use JSON qw/ encode_json decode_json /;
use Try::Tiny qw/ try catch /;
use Plack::Middleware::BufferedStreaming;
use namespace::autoclean;

with 'Message::Passing::Role::Output';

has app => (
    is => 'rw',
);

has [qw/ host port /] => (
    is => 'ro',
);

has output_to => (
    is => 'ro',
    default => sub { {} },
);

sub get_output_to {
    my ($self, $address) = @_;
    $self->output_to->{$address} ||= Message::Passing::Output::ZeroMQ->new(
        connect => $address,
        socket_type => 'PUB',
    );
}

sub consume {
    my ($self, $msg) = @_;
    my $env = decode_json($msg);
    my $errors;
    open(my $error_fh, '>', \$errors) or die $!;
    $env->{'psgi.errors'} = $error_fh;
    my $input = delete($env->{'psgi.input'}) || '';
    open(my $input_fh, '<', \$input) or die $!;
    $env->{'psgi.input'} = $input_fh;
    my $clientid = $env->{'psgix.message.passing.clientid'};
    my $reply_to = $env->{'psgix.message.passing.returnaddress'};
    my $res;
    try { $res = $self->app->($env) }
    catch {
        my $exception = "Caught exception: $_ - request aborted\n";
        $errors .= $exception;
        my $html = qq{<html><head><title>Internal server error</title></head>
            <body><h1>Internal Server Error</h1><pre>$exception</pre></body>
            </html>
        };
        $res = [
            500,
            [
                'Content-Type' => 'text/html',
                'Content-Length' => length($html),
            ],
            [ $html ]
        ];
    };
    my $return_data = encode_json({
        clientid => $clientid,
        response => $res,
        errors => $errors,
    });
    my $output_to = $self->get_output_to($reply_to);
    $output_to->consume($return_data);
}

sub run {
    my ($self, $app) = @_;
    my $buffered = Plack::Middleware::BufferedStreaming->wrap($app);
    $self->app($buffered);
    if (!$self->host) {
        die "Please specify --host with the send_address passed to Plack::App::Message::Passing\n";
    }
    if (!$self->port) {
        die "Please specify --port with the send_address port passed to Plack::App::Message::Passing\n";
    }
    my $connect_address = sprintf('tcp://%s:%s', $self->host, $self->port);
    my $input = Message::Passing::Input::ZeroMQ->new(
        connect => $connect_address,
        socket_type => 'PULL',
        output_to => $self,
    );
    AnyEvent->condvar->recv;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Plack::Handler::Message::Passing - handles PSGI requests sent via Message::Passing

=head1 SYNOPSIS

    plackup -E production -s Message::Passing testapp.psgi --host 127.0.0.1 --port 5556

=head1 DESCRIPTION

Connects via ZeroMQ to an instance of L<Plack::App::Message::Passing>, and
inflates a PSGI request from JSON, then runs it against a real application.

Returns the PSGI response and error stream to the parent handler

=head1 SEE ALSO

=over

=item L<Message::Passing::PSGI>

=item L<Plack::App::Message::Passing>

=back

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::PSGI>

=cut

