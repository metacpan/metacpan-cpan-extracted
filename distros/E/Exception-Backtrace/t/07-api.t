use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Exception::Backtrace;

use lib 't';
use MyTest;

Exception::Backtrace::install();
my $default_depth = MyTest::default_trace_depth();

plan skip_all => 'test takes too long with sanitizer' if $ENV{ASAN_OPTIONS};

subtest "perl exception thrown" => sub {
    my $ex_line;

    my $gen_bt = sub {
        my $ok = eval { $ex_line = __LINE__;  die("abc"); 1; };
        ok !$ok;
        like "$@", qr/^abc/;

        my $bt = Exception::Backtrace::get_backtrace($@);
    };
    my $bt = $gen_bt->();
    note "$bt";
    ok $bt;

    subtest "perl trace" => sub {
        my $perl_trace = $bt->perl_trace;
        ok $perl_trace;
        note "perl trace: ", $perl_trace->to_string;
        isnt index($bt->to_string, $perl_trace->to_string), -1, "whole backtrace contains perl trace";
        my $frames = $perl_trace->get_frames;
        ok $frames;
        ok (scalar(@$frames) > 2);

        subtest "main frame" => sub {
            my ($f_main) = grep { $_->library eq 'main' } @$frames;
            ok $f_main;
            is $f_main->library, 'main';
            is $f_main->file, __FILE__;
            is $f_main->line_no, $ex_line;
        };

        subtest "Test::More frame" => sub {
            my ($f_more) = grep { $_->library eq 'Test::More' } @$frames;
            ok $f_more;
            is $f_more->library, 'Test::More';
            is $f_more->file, __FILE__;
            ok $f_more->line_no;
        };

        subtest "custom args decorator" => sub {
            local $Exception::Backtrace::decorator = sub { return '[args skipped]' };
            my $str = $gen_bt->()->perl_trace->to_string;
            note "perl trace: ", $str;
            my $count = $str =~ s/args skipped//g;
            ok( $count > 4, "N times args has been skipped");
        };

        subtest "undef decorator" => sub {
            local $Exception::Backtrace::decorator = undef;
            my $str = $gen_bt->()->perl_trace->get_frames->[0]->to_string();
            note "perl farame: ", $str;
            unlike $str, qr/[()]/;
        };
    };

    SKIP: {
        skip "glibc/libunwind seems buggy on the system, skipping C trace", 1 unless $default_depth;

        subtest "C trace" => sub {
            my $c_trace = $bt->c_trace;
            ok $c_trace;
            note "c trace:\n", $c_trace->to_string;
            isnt index($bt->to_string, $c_trace->to_string), -1, "whole backtrace contains C trace";
            my $frames = $c_trace->get_frames;
            ok $frames;
            ok (scalar(@$frames) > 2);

            subtest "sample frame" => sub {
                my ($f) = grep { $_->name =~ /xs::safe_wrap_exception/ && $_->line_no } @$frames;
                if ($f) {
                    like $f->library, qr/Backtrace.(so|xs.dll)/;
                    like $f->name, qr/xs::safe_wrap_exception/;
                    like $f->file, qr/backtrace.cc/;
                    ok $f->line_no;
                    ok $f->address;
                    ok $f->offset;
                }
                else {
                    my ($f1) = grep { $_->library =~ /Backtrace\./} @$frames;
                    my ($f2) = grep { $_->library =~ /(libpanda\.)|(perl)/} @$frames;
                    ok $f1;
                    ok $f2;
                    ok $f1->address;
                    ok $f1->offset;
                    ok $f2->address;
                    ok $f2->offset;
                }
            };
        };
    };
};

SKIP: {
    skip "glibc/libunwind seems buggy on the system, skipping C trace", 1 unless $default_depth;

    subtest "C exception thrown" => sub {
        my $ex_line;
        my $ok = eval { $ex_line = __LINE__;  MyTest::throw_backtrace(); 1; };
        ok !$ok;
        like "$@", qr/panda::exception/;

        my $bt = Exception::Backtrace::get_backtrace($@);
        note "$bt";
        ok $bt;

        subtest "perl trace" => sub {
            my $perl_trace = $bt->perl_trace;
            ok $perl_trace;
            note "perl trace: ", $perl_trace->to_string;
            isnt index($bt->to_string, $perl_trace->to_string), -1, "whole backtrace contains perl trace";
            my $frames = $perl_trace->get_frames;
            ok $frames;
            ok (scalar(@$frames) > 2);

            subtest "main frame" => sub {
                my ($f_main) = grep { $_->library eq 'main' } @$frames;
                ok $f_main;
                is $f_main->library, 'main';
                is $f_main->file, __FILE__;
                is $f_main->line_no, $ex_line;
            };

            subtest "Test::More frame" => sub {
                my ($f_more) = grep { $_->library eq 'Test::More' } @$frames;
                ok $f_more;
                is $f_more->library, 'Test::More';
                is $f_more->file, __FILE__;
                ok $f_more->line_no;
            };
        };

        subtest "C trace" => sub {
            my $c_trace = $bt->c_trace;
            ok $c_trace;
            note "c trace:\n", $c_trace->to_string;
            isnt index($bt->to_string, $c_trace->to_string), -1, "whole backtrace contains C trace";
            my $frames = $c_trace->get_frames;
            ok $frames;
            ok (scalar(@$frames) > 0);

            subtest "sample frame" => sub {
                my ($f) = grep { $_->name =~ /panda::/ && $_->line_no } @$frames;
                if ($f) {
                    like $f->library, qr/libpanda.(so|xs.dll)/;
                    like $f->name, qr/panda::(exception::exception)|(Backtrace::Backtrace)/;
                    like $f->file, qr/exception.(cc|h)/;
                    ok $f->line_no;
                    ok $f->address;
                    ok $f->offset;
                }
                else {
                    my ($f1) = grep { $_->library =~ /MyTest\./} @$frames;
                    my ($f2) = grep { $_->library =~ /(libpanda\.)|(perl)/} @$frames;
                    ok $f1;
                    ok $f2;
                    ok $f1->address;
                    ok $f1->offset;
                    ok $f2->address;
                    ok $f2->offset;
                }
            };
        };
    };
};

subtest "create backtrace" => sub {
    my $bt;
    my $fn0 = sub { $bt = Exception::Backtrace::create_backtrace(); };
    my $fn1 = sub { $fn0->(@_); };
    $fn1->(5, 'str', \6, [], {}, undef, $fn0, (bless {} => 'Some::Package'));

    note "$bt";
    ok $bt;

    subtest "perl trace" => sub {
        my $perl_trace = $bt->perl_trace;;
        ok $perl_trace;
        note "perl trace: ", $perl_trace->to_string;
        isnt index($bt->to_string, $perl_trace->to_string), -1, "whole backtrace contains perl trace";
        my $frames = $perl_trace->get_frames;
        ok $frames;
        ok (scalar(@$frames) > 2);

        subtest "main frame" => sub {
            my ($f_main) = grep { $_->library eq 'main' } @$frames;
            ok $f_main;
            is $f_main->library, 'main';
            is $f_main->file, __FILE__;
            ok $f_main->line_no;

            subtest "check args" => sub {
                my $args = $f_main->args;
                ok $args;
                my @args = split(', ', $args);
                is scalar(@args), 8;
                like $args[0], qr/5/;
                like $args[1], qr/str/;
                like $args[2], qr/SCALAR/;
                like $args[3], qr/ARRAY/;
                like $args[4], qr/HASH/;
                like $args[5], qr/undef/;
                like $args[6], qr/CODE/;
                like $args[7], qr/Some::Package=HASH/;
            };
        };

        subtest "Test::More frame" => sub {
            my ($f_more) = grep { $_->library eq 'Test::More' } @$frames;
            ok $f_more;
            is $f_more->library, 'Test::More';
            is $f_more->file, __FILE__;
            ok $f_more->line_no;
        };
    };

    SKIP: {
        skip "glibc/libunwind seems buggy on the system, skipping C trace", 1 unless $default_depth;
        subtest "C trace" => sub {
            my $c_trace = $bt->c_trace;
            ok $c_trace;
            note "c trace:\n", $c_trace->to_string;
            isnt index($bt->to_string, $c_trace->to_string), -1, "whole backtrace contains C trace";
            my $frames = $c_trace->get_frames;
            ok $frames;
            ok (scalar(@$frames) > 2);

            subtest "sample frame" => sub {
                my ($f) = grep { $_->name =~ /panda::Backtrace::Backtrace/ && $_->line_no } @$frames;
                if ($f) {
                    like $f->library, qr/libpanda.(so|xs.dll)/;
                    like $f->name, qr/panda::Backtrace::Backtrace/;
                    like $f->file, qr/exception.(h|cc)/;
                    ok $f->line_no;
                    ok $f->address;
                    ok $f->offset;
                }
                else {
                    my ($f1) = grep { $_->library =~ /(libpanda\.)|(perl)/} @$frames;
                    ok $f1;
                    ok $f1->address;
                    ok $f1->offset;
                }
            };
        };
    };
};

done_testing;
