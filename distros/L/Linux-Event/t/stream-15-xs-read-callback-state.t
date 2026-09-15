use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::CallbackStateStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) { return read_size => 4 }
    sub on_data ($stream, $bytes) {
        my $state = $stream->data;
        $state->{got} .= $bytes;
        $state->{calls}++;
        if ($state->{action} eq 'close') {
            $stream->close;
            $state->{loop}->stop;
        } elsif ($state->{calls} == 1) {
            $stream->pause_read;
            $state->{loop}->stop;
        } else {
            $state->{loop}->stop if length($state->{got}) == 8;
        }
    }
}

# Closing from on_data must stop the native drain before a second callback.
socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop = Linux::Event::Loop->new;
my $close_state = { loop => $loop, action => 'close', calls => 0, got => '' };
my $stream = T::CallbackStateStream->new(
    loop => $loop,
    fh   => $a,
    data => $close_state,
);
syswrite($b, 'abcdefgh');
$loop->run;
is($close_state->{calls}, 1, 'close inside on_data stops native read drain safely');
close $b;

# Pausing from on_data must also stop the native drain until resumed.
socketpair(my $c, my $d, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!";
my $loop2 = Linux::Event::Loop->new;
my $pause_state = { loop => $loop2, action => 'pause', calls => 0, got => '' };
my $stream2 = T::CallbackStateStream->new(
    loop => $loop2,
    fh   => $c,
    data => $pause_state,
);
syswrite($d, 'abcdefgh');
$loop2->run;
is(length($pause_state->{got}), 4, 'pause inside callback stops further native reads');
$stream2->resume_read;
$loop2->run;
is($pause_state->{got}, 'abcdefgh', 'resume continues native read drain');
$stream2->close;
close $d;

done_testing;
