use Test::More;
use Test::Exception;

use Carp;
use POSIX qw(locale_h);
setlocale(LC_ALL, 'C');

use EV;
use IO::Stream;

use Carp::Heavy;
$SIG{PIPE}  = 'IGNORE';
$EV::DIED   = sub { diag $@; EV::unloop };

#use t::config;

if (`emu-g -h 2>&1` !~ /Usage/xmsi) {
    plan skip_all => 'require OS Inferno to run this test';
}

my ($inferno_pid, $inferno_fh);
sub registry_start {
    $inferno_pid = open $inferno_fh, '|-',
     'EMU=-r/usr/inferno INFERNO_HOME=$(pwd)/t/inferno/ /usr/inferno/Linux/386/bin/emu-g sh -c "run /lib/sh/profile; reg2tcp"'
     or die "open: $!";
    sleep 1;    # WARNING unreliable
}
sub registry_stop {
    kill 15, $inferno_pid;
}

### Usage example:
#@CheckPoint = (
#    [ 'listener',   ACCEPTED        ], 'accept incoming connection',
#    [ 'ssl_client', IN              ], 'client: got server banner',
#    [ 'ssl_client', $banner         ], 'client: banner is correct',
#    [ 'ssl_client', SENT            ], 'client: request sent',
#    [ 'ssl_server', EOF             ], 'server: got eof',
#    [ 'ssl_server', $msg            ], 'server: requst is correct',
#    [ 'ssl_server', SENT            ], 'server: reply sent',
#    [ 'ssl_client', EOF             ], 'client: got eof',
#    [ 'ssl_client', "echo: $msg"    ], 'client: reply is correct',
#);
#plan tests => @CheckPoint/2;
use vars qw( @CheckPoint );
sub checkpoint {
    my ($func) = (caller(1))[3]=~/.*::(.*)/;
    is_deeply([$func, @_], shift @CheckPoint, shift @CheckPoint);
    return;
}

### Usage example:
#sub client {
#    my ($io, $e, $err) = @_;
#  &diag_event;
#}
sub diag_event {
    my ($io, $e, $err) = @_;
    my ($func) = (caller(1))[3]=~/.*::(.*)/;
    diag "$func : ".events2str($e, $err);
}

sub events2str {
    my ($e, $err) = @_;
    my @e = ($e & RESOLVED, $e & CONNECTED, $e & IN, $e & OUT, $e & EOF, $e & SENT, $e & ~(RESOLVED|CONNECTED|IN|OUT|EOF|SENT));
    my @n = qw(RESOLVED CONNECTED IN OUT EOF SENT unk);
    my $s = join q{|}, map {$e[$_] ? $n[$_] : ()} 0 .. $#e;
    return $err ? "$s err=$err" : $s;
}

1;
