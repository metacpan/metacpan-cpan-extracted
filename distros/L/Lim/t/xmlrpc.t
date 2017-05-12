#!perl -T

use Test::More tests => 1;

eval {
    use XMLRPC::Transport::HTTP::Server ();
};
BAIL_OUT($@) if ($@);

exit unless pipe(READP, WRITEP);
WRITEP->autoflush(1);
my $pid = $$;
my $child = fork();

unless ($child) {
    use Log::Log4perl ();

    use AnyEvent ();

    use Lim::RPC::Server ();
    use Lim::Agent ();

    Log::Log4perl->init( \q(
    log4perl.logger                   = DEBUG, Screen
    log4perl.appender.Screen          = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr   = 0
    log4perl.appender.Screen.layout   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = %d %F [%L] %p: %m%n
    ) );

    my $cv = AnyEvent->condvar;
    my @watchers;

    push(@watchers,
        AnyEvent->signal(signal => "INT", cb => sub {
            $cv->send;
        }),
        AnyEvent->signal(signal => "QUIT", cb => sub {
            $cv->send;
        }),
        AnyEvent->signal(signal => "TERM", cb => sub {
            $cv->send;
        }),
    );
    
    my $server = Lim::RPC::Server->new(
        uri => 'http+xmlrpc://127.0.0.1:0'
    );
    $server->serve(qw(Lim::Agent));
    push(@watchers, $server, AnyEvent->timer(after => 0, cb => sub {
        my $port = '';
        foreach ($server->transports) {
            $port = $_->port;
            last;
        }
        print WRITEP $port,"\n";
    }));
    $cv->recv;
    @watchers = ();
    exit;
}

use Lim ();
use XMLRPC::Lite;

$SIG{ALRM} = sub { exit; };
alarm(10);
my $port = <READP>;
alarm(0);
chomp($port);

if ($port =~ /^\d+$/o) {
    my $res =
        XMLRPC::Lite
        -> proxy('http://127.0.0.1:'.$port.'/agent')
        -> call('ReadVersion')
        -> result;
    
    if (ref($res) eq 'HASH') {
        $res = $res->{version};
    }

    ok($res eq $Lim::VERSION);
}

kill 15, $child;
