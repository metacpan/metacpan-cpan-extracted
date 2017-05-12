# Resources (mem/fd) shouldn't leak.
use warnings;
use strict;
use t::share;

if ($^O !~ /linux/i) {
    plan skip_all => 'require /proc';
}

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

if ($INC{'Devel/Cover.pm'}) {
    plan skip_all => 'unable to test under Devel::Cover';
}
plan tests => 2;

leaktest('create_stream');

sub create_stream {
    IO::Stream->new({
        host        => '127.0.0.1',
        port        => 1234,
        cb          => sub {},
        wait_for    => 0,
    })->close();
}

sub leaktest {
    my $test = shift;
    my %arg  = (init=>100, test=>1000, max_mem_diff=>100, diag=>0, @_);
    my $code = do { no strict 'refs'; \&$test };
    $code->() for 1 .. $arg{init};
    my $fd  = FD_used();
    my $mem = MEM_used();
    $code->() for 1 .. $arg{test};
    diag sprintf "---- MEM\nWAS: %d\nNOW: %d\n", $mem, MEM_used() if $arg{diag};
    ok( abs(MEM_used() - $mem) < $arg{max_mem_diff},  "MEM: $test" );
    is(FD_used(), $fd,                                " FD: $test" );
}

sub MEM_used {
    open my $f, '<', '/proc/self/status';
    my $status = join q{}, <$f>;
    return ($status =~ /VmRSS:\s*(\d*)/)[0];
};

sub FD_used {
    opendir my $fd, '/proc/self/fd' or croak "opendir: $!";
    return @{[ readdir $fd ]} - 2;
};

