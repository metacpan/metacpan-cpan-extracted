use 5.012;
use warnings;
use IO::Handle;
use Test::More;
use Test::Warnings;
use Exception::Backtrace;

use lib 't';
use MyTest;

Exception::Backtrace::install();

subtest "default decorator" => sub {
    my $bt;
    my $fn0 = sub { $bt = Exception::Backtrace::create_backtrace(); };
    my $fn1 = sub { $fn0->(@_); };
    $fn1->(5, 5.5, 'str', \6, [], {}, undef, $fn0, (bless {} => 'Some::Package'));
    my $frame = $bt->perl_trace->get_frames->[0];
    like $frame->to_string, qr/main::__ANON__\(5, 5.5, str, SCALAR\(0x\w+\), ARRAY\(0x\w+\), HASH\(0x\w+\), undef, CODE\(0x\w+\), Some::Package=HASH\(0x\w+\)\)/;
};


subtest "PVLV in args" => sub {
    my $bt;
    my $fn0 = sub { $bt = Exception::Backtrace::create_backtrace(); };
    my $fn1 = sub { $fn0->(@_); };
    my $hash = {};
    my $str = 'aaa';
    $fn1->($hash->{key}, substr($str, 0, 1));
    my $frame = $bt->perl_trace->get_frames->[0];
    like $frame->to_string, qr/main::__ANON__\(undef, a\)/;
};

subtest "exotic args (io, glob, regex)" => sub {
    my $bt;
    my $fn0  = sub { $bt = Exception::Backtrace::create_backtrace(); };
    my $fn1  = sub { $fn0->(@_); };
    my $io   = *STDOUT{IO};
    my $glob = *STDOUT;
    $fn1->($io, $glob, qr/z+/);
    my $frame = $bt->perl_trace->get_frames->[0];
    like $frame->to_string, qr/main::__ANON__\(IO::File=IO\(.+?\), \*main::STDOUT, .+\Qz+\E.+\)/;
};

subtest "delete one of arg, undef is reported" => sub {
    my $bt;
    my $fn0 = sub { $bt = Exception::Backtrace::create_backtrace(); };
    my $fn1 = sub { $fn0->(undef $_[0]); };
    $fn1->([]);
    my $frame = $bt->perl_trace->get_frames->[1];
    like $frame->to_string, qr/main::__ANON__\(undef\)/;
};

SKIP: {
    skip "need JSON::XS", 1 unless eval "use JSON::XS; 1";
    my $bt;
    my $decorator = sub { "--==(" . JSON::XS::encode_json($_[0]) . ")==--" };
    local $Exception::Backtrace::decorator = $decorator;

    my $fn0 = sub { $bt = Exception::Backtrace::create_backtrace(); };
    my $fn1 = sub { $fn0->(@_); };
    $fn1->({a => [1,2,3]});
    my $frame = $bt->perl_trace->get_frames->[1];
    like $frame->to_string(), qr/\Q--==([{"a":[1,2,3]}])==--\E/;
};

subtest "exception in decorator stringizing" => sub {
    package Bad::Package {
        use overload '""' => sub { ...; };
    };

    my $bt;
    my $fn0 = sub { $bt = Exception::Backtrace::create_backtrace(); };
    my $fn1 = sub { $fn0->($_[0]); };
    $fn1->((bless {} => 'Bad::Package'));
    my $frame = $bt->perl_trace->get_frames->[1];
    like $frame->to_string, qr/\Q(*exception*)\E/;
};

SKIP: {
    skip "need BSD::Resource", 1 unless eval "use BSD::Resource; 1";
    skip "test is unstable under sanitizer", 1 if $ENV{ASAN_OPTIONS};

    my $fn0 = sub { die $_[0]  };
    my $fn1 = sub { $fn0->(@_) };

    my $test_it = sub { eval { $fn1->((bless {} => 'Bad::Package')); } };

    # warm up
    $test_it->() for 1..100;
    my $initial = BSD::Resource::getrusage()->{"maxrss"};

    $test_it->() for(1 .. 1000);

    my $final = BSD::Resource::getrusage()->{"maxrss"};

    note "mem usage $initial / $final";
    cmp_ok $final - $initial, '<', 100;
};



done_testing;
