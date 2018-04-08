# Resources (mem/fd) shouldn't leak.
use warnings;
use strict;
use lib 't';
use share;

if ($INC{'Devel/Cover.pm'}) {
    plan skip_all => 'unable to test under Devel::Cover';
}

leaktest('create_client_stream');
leaktest('create_server_stream');

done_testing();


sub create_client_stream {
    IO::Stream->new({
        host        => '127.0.0.1',
        port        => 1234,
        cb          => sub {},
        wait_for    => 0,
        plugin      => [
            ssl         => IO::Stream::MatrixSSL::Client->new({}),
        ],
    })->close();
}

sub create_server_stream {
    IO::Stream->new({
        host        => '127.0.0.1',
        port        => 1234,
        cb          => sub {},
        wait_for    => 0,
        plugin      => [
            ssl         => IO::Stream::MatrixSSL::Server->new({
                crt         => 't/cert/testsrv.crt',
                key         => 't/cert/testsrv.key',
            }),
        ],
    })->close();
}

sub leaktest {
    my $test = shift;
    my %arg  = (init=>10, test=>1000, max_mem_diff=>(WIN32?512:288), diag=>0, @_);
    my $tmp = 'x' x 1000000; undef $tmp;
    my $code = sub { no strict 'refs'; \&$test(); };
    $code->() for 1 .. $arg{init};
    my $mem = MEM_used();
    my $fd  = FD_used();
    $code->() for 1 .. $arg{test};
    diag sprintf("---- MEM $test\nWAS: %d\nNOW: %d\n", $mem, MEM_used()) if $arg{diag};
    cmp_ok(abs(MEM_used() - $mem), '<=', $arg{max_mem_diff}, "MEM: $test" );
    is(FD_used(), $fd, " FD: $test" );
}

sub Cat {
    croak 'usage: Cat( FILENAME )' if @_ != 1;
    my ($filename) = @_;
    open my $f, '<', $filename or croak "open: $!";
    local $/ if !wantarray;
    return <$f>;
}

sub MEM_used {
    if ($^O =~ /linux/) {
        return (Cat('/proc/self/status') =~ /VmRSS:\s*(\d*)/)[0];
    }
    elsif ($^O =~ /Win32/) {
        # FIXME this will fail on non-English Win7
        my ($m) = `tasklist /nh /fi "PID eq $$"` =~/.*\s([\d,]+)/;
        $m=~tr/,//d;
        return $m;
    }
    else {
        return (`ps -o'rss' -p $$` =~ /(\d+)/);
    }
}

sub FD_used {
    if ($^O =~ /linux/) {
        opendir my $fd, '/proc/self/fd' or croak "opendir: $!";
        return @{[ readdir $fd ]} - 2;
    }
    else {
        return 0;
    }
}
