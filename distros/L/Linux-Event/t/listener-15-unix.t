use v5.36;
use strict;
use warnings;
use Test::More;
use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use Socket qw(AF_UNIX SOCK_STREAM pack_sockaddr_un);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;

{
    package T::UnixStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_ready ($stream) {
        $stream->data->{peer} = $stream->peer;
        $stream->data->{stream} = $stream;
        $stream->loop->stop;
    }
    sub on_data ($stream, $bytes) { }
}

my $directory = tempdir(CLEANUP => 1);
my $path = "$directory/listen.sock";
my $loop = Linux::Event::Loop->new;
my $state = {};
my $listener;
eval {
    $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop, unix => $path, permissions => 0600,
        stream => { class => 'T::UnixStream', data => $state },
    );
    1;
} or plan skip_all => "Unix stream listeners unavailable: $@";

ok(-S $path, 'created Unix listener has a socket path');
is((stat($path))[2] & 0777, 0600, 'Unix listener applies permissions');
is($listener->family, 'unix', 'Unix Listener reports symbolic family');
is($listener->family_number, AF_UNIX,
    'Unix Listener reports native family separately');
ok($listener->is_unix, 'Unix Listener identifies as Unix');
ok(!$listener->is_tcp, 'Unix Listener does not identify as TCP');
socket(my $client, AF_UNIX, SOCK_STREAM, 0) or die "socket: $!";
connect($client, pack_sockaddr_un($path)) or die "connect: $!";
$loop->run;
ok(!$state->{error}, 'Unix accept succeeds');
is($state->{peer}->family, 'unix', 'Unix peer exposes address family');

$state->{stream}->close;
close $client;
$listener->close;
ok(!-e $path, 'owned Unix listener removes path on close');

my $original_directory = getcwd();
chdir $directory or die "chdir $directory: $!";
my $zero_path_listener = Linux::Event::IO::Sock::Listener->new(
    stream       => { class => 'T::UnixStream' },
    unix         => '0',             # required
);
ok(-S '0', 'relative Unix listener path named zero is created');
$zero_path_listener->close;
ok(!-e '0', 'relative Unix listener path named zero is removed on close');
chdir $original_directory or die "chdir $original_directory: $!";

done_testing;
