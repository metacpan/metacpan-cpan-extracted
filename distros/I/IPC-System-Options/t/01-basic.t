#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Cwd;
use File::Temp qw(tempfile tempdir);
use IPC::System::Options qw(system readpipe run);

subtest system => sub {

    subtest "unknown option -> die" => sub {
        dies_ok { system({foo => 1}, $^X, "-e1") };
    };

    subtest "opt:die" => sub {
        lives_ok { system(rand()) };
        dies_ok { system({die=>1}, rand()) };
    };

    subtest "opt:env" => sub {
        my $stdout;
        system({capture_stdout=>\$stdout, env=>{FOO=>123}}, $^X, "-e", 'print $ENV{FOO}');
        is_deeply($stdout, "123");
    };

    subtest "opt:capture_stdout" => sub {
        my $stdout;
        system({capture_stdout=>\$stdout}, $^X, "-e", "print 123");
        is_deeply($stdout, "123");
    };

    subtest "opt:capture_stderr" => sub {
        my $stderr;
        system({capture_stderr=>\$stderr}, $^X, "-e", "warn 123");
        like($stderr, qr/123/);
    };

    subtest "opt:capture_merged" => sub {
        my $merged;
        system({capture_merged=>\$merged}, $^X, "-e", "\$|++; print 123; print STDERR 456; print 789");
        is_deeply($merged, "123456789");
    };

    # XXX opt:shell
    # XXX opt:lang
    # XXX opt:log
    # XXX opt:dry_run

    subtest "opt:chdir" => sub {
        my $tempdir = tempdir(CLEANUP => 1);
        lives_ok { system({die=>1, chdir=>$tempdir}, $^X, "-e1") };
        dies_ok  { system({die=>1, chdir=>"$tempdir/sub"}, $^X, "-e1") };
        # XXX test $? set to -1 if chdir fails
        # XXX test $? set to -1 (only if $? from command was zero) if chdir back fails
        # XXX test chdir back fails
    };

};

subtest readpipe => sub {
    is(readpipe($^X, "-e", "print 123"), "123");

    # XXX opt:max_log_output
    ok 1;
};

subtest run => sub {
    subtest "opt:stdin" => sub {
        my $stdout;
        run({stdin=>"123", capture_stdout=>\$stdout}, $^X, "-e", "print <>");
        is_deeply($stdout, "123");
    };
    ok 1;
};

# XXX test global options

done_testing;
