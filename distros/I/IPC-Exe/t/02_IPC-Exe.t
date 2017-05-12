use warnings;
use strict;

my $DEBUG = 0;

use Test::More;
use Scalar::Util qw(refaddr);
use Data::Dumper;

BEGIN {
    # need 5.6+ for lexical filehandles
    if ($] < 5.006_000)
    {
        plan skip_all => "- Perl v5.6.0+ required.";
    }

    # unfortunately, some platforms are not supported
    #   some of these platforms cannot fork()
    if ($^O =~ /^(?:VMS|dos|MacOS|riscos|amigaos|vmesa)$/)
    {
        plan skip_all => "- platform not supported: $^O";
    }
}

BEGIN { plan tests => 91 }
#BEGIN { plan "no_plan" }

# can we use the module?
use lib "../lib";
BEGIN { use_ok("IPC::Exe", qw(exe bg)); }

# timeout handling
eval "use Time::HiRes qw(alarm)";
sub timeout (&@) {
    my $cb = shift();
    my $test_name = shift();
    my $wait = shift() || 5;

    local $SIG{__DIE__};
    local $@ = "";

    eval {
        local $SIG{ALRM} = sub { die("alarm\n") };

        alarm($wait);
        $cb->($test_name); # potentially long operation
        alarm(0);

        1;
    } or do {
        BAIL_OUT($@) unless $@ eq "alarm\n";

        # timed out
        fail($test_name);
    }
}

# create generators
my $gen_out = [
    [ $^X, '-le', 'print STDOUT $_ for qw(line1 line2 line3); exit 44' ],
    [ qw(line1 line2 line3) ],
];
my $gen_err = [
    [ $^X, '-le', 'print STDERR $_ for qw(line4 line5 line6); exit 77' ],
    [ qw(line4 line5 line6) ],
];

# manual loop exit required for non-Unix platforms
my $non_unix = ($^O =~ /^(?:MSWin32|os2)$/);
my $exit_loop = $non_unix ? 'last if /line[36]$/' : '';

# create filters
my $filt_out_1 = [
    [ $^X, '-e', 'while (<STDIN>) { print STDOUT "from_out_1> $_";' . $exit_loop . '}' ],
    "from_out_1> ",
];
my $filt_out_2 = [
    [ $^X, '-e', 'while (<STDIN>) { print STDOUT "from_out_2> $_";' . $exit_loop . '}' ],
    "from_out_2> ",
];
my $filt_err_1 = [
    [ $^X, '-e', 'while (<STDIN>) { print STDERR "from_err_1> $_";' . $exit_loop . '}' ],
    "from_err_1> ",
];
my $filt_err_out = [
    [ $^X, '-e', '$| = 1; while (<STDIN>) { print STDERR "filt_err_out> $_"; print STDOUT "filt_err_out> $_";' . $exit_loop . '}' ],
    "filt_err_out> ",
];

# syntax
{
    my @result1 = exe();
    my @result2 = bg();
    my $sub_ref = sub { };
    my $result3 = exe $sub_ref;

    is_deeply(\@result1, [ ], "syntax: exe() empty list");
    is_deeply(\@result2, [ ], "syntax: bg() empty list");
    is(refaddr($result3), refaddr($sub_ref), "syntax: exe() sub only");

    diag Dumper(\@result1, \@result2, $result3, $sub_ref) if $DEBUG;
}

# exit status
{
    ($?, $!, $^E, $@) = (55, 66, 66, "e");

    my @pids1 = &{
        exe sub { "1>#" }, @{ $gen_out->[0] },
    };

    ok( defined($pids1[0]), "exit: gen_out pid");
    is($?        >> 8, 44,  "exit: gen_out exit status \$?");
    is($!  + 0       , 66,  "exit: gen_out exit status \$!");
    is($^E + 0       , 66,  "exit: gen_out exit status \$^E");
    is($@            , "e", "exit: gen_out exit status \$@");
    is($pids1[1] >> 8, 44,  "exit: gen_out exit status return");

    my @pids2 = &{
        exe sub { "2>#" }, @{ $gen_err->[0] },
    };

    ok( defined($pids2[0]), "exit: gen_err pid");
    is($?        >> 8, 77,  "exit: gen_err exit status \$?");
    is($!  + 0       , 66,  "exit: gen_err exit status \$!");
    is($^E + 0       , 66,  "exit: gen_err exit status \$^E");
    is($@            , "e", "exit: gen_err exit status \$@");
    is($pids2[1] >> 8, 77,  "exit: gen_err exit status return");

    my @pids3 = &{
        exe @{ $gen_out->[0] }, \"1>#",
        sub {
            # same as before exe was invoked
            is($?        >> 8, 77,  "exit_fake_pre: gen_err exit status \$?");
            is($!  + 0       , 66,  "exit_fake_pre: gen_err exit status \$!");
            is($^E + 0       , 66,  "exit_fake_pre: gen_err exit status \$^E");
            is($@            , "e", "exit_fake_pre: gen_err exit status \$@");

            # avoid implicit close() that clobbers $! / $^E
            close($IPC::Exe::PIPE);

            $@ = "k";
            $! = $^E = 33;
            $? = $! << 8;
        }
    };

    ok( defined($pids3[0]), "exit_fake_post: gen_out pid");
    is($?        >> 8, 33,  "exit_fake_post: exit status \$?");
    is($!  + 0       , 33,  "exit_fake_post: exit status \$!");
    is($^E + 0       , 33,  "exit_fake_post: exit status \$^E");
    is($@            , "k", "exit_fake_post: exit status \$@");
    is($pids3[1] >> 8, 33,  "exit_fake_post: exit status return");

    my @pids4 = &{
        exe @{ $gen_out->[0] }, \"1>#",
        sub { $? = 22 << 8; waitpid($_[0], 0); $? }
    };

    ok( defined($pids4[0]), "exit_waitpid: gen_out pid");
    is($?        >> 8, 44,  "exit_waitpid: exit status \$?");
    is($pids4[1] >> 8, 44,  "exit_waitpid: exit status return");

    diag Dumper(\@pids1, \@pids2, \@pids3, \@pids4) if $DEBUG;
}

# exit status by closing pipe
SKIP: {
    skip("- exit_close_pipe: platform limitation", 3) if $non_unix;

    my @pids = &{
        exe @{ $gen_out->[0] }, \"1>#",
        sub { $? = 33 << 8; close($IPC::Exe::PIPE); $? }
    };

    ok( defined($pids[0]), "exit_close_pipe: gen_out pid");
    is($?       >> 8, 44,  "exit_close_pipe: exit status \$?");
    is($pids[1] >> 8, 44,  "exit_close_pipe: exit status return");

    diag Dumper(\@pids) if $DEBUG;
}

# simple case
{
    my @pids = &{
        exe @{ $gen_out->[0] },
        sub {
            timeout {
                chomp(my @result = <STDIN>);
                my @expected =
                  @{ $gen_out->[1] };
                is_deeply(\@result, \@expected, $_[0]);
            } "simple: gen_out only";
        },
    };

    ok( defined($pids[0]), "simple: gen_out pid");

    diag Dumper(\@pids) if $DEBUG;
}

# one filter
{
    my @pids = &{
        exe @{ $gen_out->[0] },
        exe @{ $filt_out_1->[0] },
        sub {
            timeout {
                chomp(my @result = <STDIN>);
                my @expected =
                  map { $filt_out_1->[1] . $_ }
                  @{ $gen_out->[1] };

                is_deeply(\@result, \@expected, $_[0]);
            } "one_filter: gen_out + filt_out_1";
        },
    };

    ok( defined($pids[0]), "one_filter: gen_out pid");
    ok( defined($pids[1]), "one_filter: filt_out_1 pid");

    diag Dumper(\@pids) if $DEBUG;
}

# two filters
{
    my @pids = &{
        exe @{ $gen_out->[0] },
        exe @{ $filt_out_1->[0] },
        exe @{ $filt_out_2->[0] },
        sub {
            timeout {
                chomp(my @result = <STDIN>);
                my @expected =
                  map { $filt_out_2->[1] . $_ }
                  map { $filt_out_1->[1] . $_ }
                  @{ $gen_out->[1] };

                is_deeply(\@result, \@expected, $_[0]);
            } "two_filters: gen_out + filt_out_1 + filt_out_2";
        },
    };

    ok( defined($pids[0]), "two_filters: gen_out pid");
    ok( defined($pids[1]), "two_filters: filt_out_1 pid");
    ok( defined($pids[2]), "two_filters: filt_out_2 pid");

    diag Dumper(\@pids) if $DEBUG;
}

# quoting
{
    my @pids1 = &{
        exe $^X, '-e', 'print " \"\t\\\\\n"',
        sub {
            timeout {
                my $result = <STDIN>;
                is($result, " \"\t\\\n", $_[0]);
            } "quoting: escaped argument";
        },
    };

    my @pids2 = &{
        exe $^X, '-le', 'print scalar grep { $_ eq "" } @ARGV', '', '',
        sub {
            timeout {
                chomp(my $result = <STDIN>);
                is($result, 2, $_[0]);
            } "quoting: empty arguments";
        },
    };

    diag Dumper(\@pids1, \@pids2) if $DEBUG;
}

# arguments to &PREEXEC and &READER
{
    my $cb =
      exe sub { print "$_\n" for @_ }, @{ $gen_out->[0] },
      sub {
          timeout {
              chomp(my @result = <STDIN>);
              my @expected = (
                  @{ $gen_err->[1] },
                  @{ $gen_out->[1] },
              );

              is_deeply(\@result, \@expected, $_[0]);
          } "arguments: to &PREEXEC";

          return [ @_ ];
      };

    my @pids = $cb->(@{ $gen_err->[1] });

    ok( defined($pids[0]), "arguments: gen_out pid");
    is_deeply($pids[1], [ $pids[0], @{ $gen_out->[0] } ], "arguments: to &READER");

    diag Dumper(\@pids) if $DEBUG;
}

# redirect to null
{
    my @pids = &{
        exe @{ $gen_out->[0] }, \">#",
        sub {
            timeout {
                chomp(my @result = <STDIN>);
                is_deeply(\@result, [ ], $_[0]);
            } "redir_null: silence";
        },
    };

    ok( defined($pids[0]), "redir_null: gen_out pid");

    diag Dumper(\@pids) if $DEBUG;
}

# redirect STDERR to STDOUT
{
    my @pids = &{
        exe @{ $gen_err->[0] }, \"2>&1",
        sub {
            timeout {
                chomp(my @result = <STDIN>);
                my @expected =
                  @{ $gen_err->[1] };
                is_deeply(\@result, \@expected, $_[0]);
            } "redir_err2out: gen_err only";
        },
    };

    ok( defined($pids[0]), "redir_err2out: gen_err pid");

    diag Dumper(\@pids) if $DEBUG;
}

# redirect STDERR to STDOUT with filters
{
    my @pids = &{
        exe @{ $gen_err->[0] }, [ "2>&" . fileno(*STDOUT) ],
        exe @{ $filt_err_1->[0] }, \"6>&1", \"3>&6", \"2>&3", \"6>&-", \"3>&-",
        exe @{ $filt_out_2->[0] },
        sub {
            timeout {
                chomp(my @result = <STDIN>);
                my @expected =
                  map { $filt_out_2->[1] . $_ }
                  map { $filt_err_1->[1] . $_ }
                  @{ $gen_err->[1] };
                is_deeply(\@result, \@expected, $_[0]);
            } "redir_err2out_with_filters: gen_err + filt_err_1 + filt_out_2";
        },
    };

    ok( defined($pids[0]), "redir_err2out_with_filters: gen_err pid");
    ok( defined($pids[1]), "redir_err2out_with_filters: filt_err_1 pid");
    ok( defined($pids[2]), "redir_err2out_with_filters: filt_out_2 pid");

    diag Dumper(\@pids) if $DEBUG;
}

# undefined command
{
    local $SIG{__WARN__} = sub { }; # silence warning

    my @pids = &{
        exe sub { "2>#" }, undef,
    };

    is_deeply(\@pids, [ ], "undef_cmd: return empty list");

    diag Dumper(\@pids) if $DEBUG;
}

# bad command
{
    my @pids = &{
        exe sub { "2>#" }, "DOES_NOT_EXIST",
    };

    is($pids[1], -1, "bad_cmd: return failed exec status");

    ok(!defined($pids[0]), "bad_cmd: no pid");

    diag Dumper(\@pids) if $DEBUG;
}

# bad command with filter
{
    my @pids = &{
        exe "DOES_NOT_EXIST", \"2>#",
        exe @{ $filt_out_1->[0] },
    };

    ok(!defined($pids[0]), "bad_cmd_with_filter: no pid");
    ok( defined($pids[1]), "bad_cmd_with_filter: filt_out_1 pid");

    diag Dumper(\@pids) if $DEBUG;
}

# bad filter
{
    my @pids1 = &{
        exe @{ $gen_out->[0] },
        exe "DOES_NOT_EXIST", \"2>#",
    };

    ok( defined($pids1[0]), "bad_filter: gen_out pid");
    ok(!defined($pids1[1]), "bad_filter: no filter pid");

    my @pids2;
    local $@;
    eval {
        @pids2 = &{
            exe @{ $gen_out->[0] },
            sub { die "donkey\n" },
        };
    };

    is($@, "donkey\n", "bad_filter: &READER dies \$@");
    is(scalar(@pids2), 0, "bad_filter: &READER dies no pids");

    diag Dumper(\@pids1, \@pids2) if $DEBUG;
}

# bad filter sandwich 1
{
    my @pids = &{
        exe @{ $gen_out->[0] },
        exe sub { "2>#" }, "DOES_NOT_EXIST",
        exe @{ $filt_out_2->[0] },
    };

    ok( defined($pids[0]), "bad_filter_sandwich_1: gen_out pid");
    ok(!defined($pids[1]), "bad_filter_sandwich_1: no filter pid");
    ok( defined($pids[2]), "bad_filter_sandwich_1: filt_out_2 pid");

    diag Dumper(\@pids) if $DEBUG;
}

# bad filter sandwich 2
{
    my @pids1 = &{
        exe @{ $gen_out->[0] },
        exe @{ $filt_out_1->[0] },
        exe sub { "2>#" }, "DOES_NOT_EXIST",
    };

    ok( defined($pids1[0]), "bad_filter_sandwich_2: gen_out pid");
    ok( defined($pids1[1]), "bad_filter_sandwich_2: filt_out_1 pid");
    ok(!defined($pids1[2]), "bad_filter_sandwich_2: no filter pid");

    my @pids2;
    local $@;
    eval {
        @pids2 = &{
            exe @{ $gen_out->[0] },
            exe @{ $filt_out_1->[0] },
            sub { die "piglet\n" },
        };
    };

    is($@, "piglet\n", "bad_filter_sandwich_2: &READER dies \$@");
    is(scalar(@pids2), 0, "bad_filter_sandwich_2: &READER dies no pids");

    diag Dumper(\@pids1, \@pids2) if $DEBUG;
}

# trickle pipe (data smaller than pipe buffer)
{
    my @pids = &{
        exe sub {
            print "a" x 50, "\n" for 1 .. 4;
        },
        sub {
            timeout {
                my $cnt = 0;

                while (my $result = <STDIN>)
                {
                    chomp($result);
                    ++$cnt if length($result) == 50;
                }

                is($cnt, 4, $_[0]);
            } "trickle_pipe: perlsub generates lines";
        },
    };

    diag Dumper(\@pids) if $DEBUG;
}

# trickle pipe program generates lines
{
    my @pids = &{
        exe $^X, '-e', 'print "a" x 50, "\n" for 1 .. 4',
        sub {
            timeout {
                my $cnt = 0;

                while (my $result = <STDIN>)
                {
                    chomp($result);
                    ++$cnt if length($result) == 50;
                }

                is($cnt, 4, $_[0]);
            } "trickle_pipe: program generates lines";
        },
    };

    diag Dumper(\@pids) if $DEBUG;
}

# burst pipe (data larger than pipe buffer)
SKIP: {
    skip("- burst_pipe: platform limitation", 1) if $non_unix;

    my @pids = &{
        exe sub {
            print "a" x 100, "\n" for 1 .. 200;
        },
        sub {
            timeout {
                my $cnt = 0;

                while (my $result = <STDIN>)
                {
                    chomp($result);
                    ++$cnt if length($result) == 100;
                }

                is($cnt, 200, $_[0]);
            } "burst_pipe: perlsub generates short lines";
        },
    };

    diag Dumper(\@pids) if $DEBUG;
}

# burst pipe perlsub generates long lines
SKIP: {
    skip("- burst_pipe: platform limitation", 1) if $non_unix;

    my @pids = &{
        exe sub {
            print "a" x 9000, "\n" for 1 .. 3;
        },
        sub {
            timeout {
                my $cnt = 0;

                while (my $result = <STDIN>)
                {
                    chomp($result);
                    ++$cnt if length($result) == 9000;
                }

                is($cnt, 3, $_[0]);
            } "burst_pipe: perlsub generates long lines";
        },
    };

    diag Dumper(\@pids) if $DEBUG;
}

# burst pipe program generates short lines
{
    my @pids = &{
        exe $^X, '-e', 'print "a" x 100, "\n" for 1 .. 200',
        sub {
            timeout {
                my $cnt = 0;

                while (my $result = <STDIN>)
                {
                    chomp($result);
                    ++$cnt if length($result) == 100;
                }

                is($cnt, 200, $_[0]);
            } "burst_pipe: program generates short lines";
        },
    };

    diag Dumper(\@pids) if $DEBUG;
}

# burst pipe program generates long lines
{
    my @pids = &{
        exe $^X, '-e', 'print "a" x 9000, "\n" for 1 .. 3',
        sub {
            timeout {
                my $cnt = 0;

                while (my $result = <STDIN>)
                {
                    chomp($result);
                    ++$cnt if length($result) == 9000;
                }

                is($cnt, 3, $_[0]);
            } "burst_pipe: program generates long lines";
        },
    };

    diag Dumper(\@pids) if $DEBUG;
}

# in forked thread/process?
{
    my @pids = &{
        exe sub {
                print "forked\n" if $IPC::Exe::is_forked;
                print "failed\n";
            },
        sub {
            timeout {
                chomp(my $result = <STDIN>);
                is($result, "forked", $_[0] . "child");

                ok(!$IPC::Exe::is_forked, $_[0] . "parent");
            } "is_forked: in exe() ";
        },
    };

    diag Dumper(\@pids) if $DEBUG;
}

# simple interactivity to STDOUT
{
    local $SIG{CHLD} = 'IGNORE';

    my ($pid, $TO_STDIN, $FROM_STDOUT) = &{
        exe +{ stdin => 1, stdout => 1 }, sub { "2>&1" }, @{ $filt_err_1->[0] },
    };

    ok( defined($pid), "interact_out: filt_err_1 pid");

    print $TO_STDIN "$_\n" for qw(line1 line2 line3);

    timeout {
        my @result;
        push(@result, scalar <$FROM_STDOUT>) for 1 .. 3;
        s/[\r\n]*\z// for @result; # chomp(@result);

        my @expected =
          map { $filt_err_1->[1] . $_ }
          @{ $gen_out->[1] };
        is_deeply(\@result, \@expected, $_[0]);
    } "interact_out: from stdout";

    close($TO_STDIN);
    close($FROM_STDOUT);

    diag Dumper([ $pid, $TO_STDIN, $FROM_STDOUT ]) if $DEBUG;
}

# simple interactivity to STDERR
{
    local $SIG{CHLD} = 'IGNORE';

    my ($pid, $FROM_STDERR);
    my ($TO_STDIN) = &{
        exe +{ pid => \$pid, stdin => 1, stderr => \$FROM_STDERR },
          @{ $filt_err_1->[0] },
        sub { }, # avoid using default &READER
    };

    ok( defined($pid), "interact_err: filt_err_1 pid");

    print $TO_STDIN "$_\n" for qw(line4 line5 line6);

    timeout {
        my @result;
        push(@result, scalar <$FROM_STDERR>) for 1 .. 3;
        s/[\r\n]*\z// for @result; # chomp(@result);

        my @expected =
          map { $filt_err_1->[1] . $_ }
          @{ $gen_err->[1] };
        is_deeply(\@result, \@expected, $_[0]);
    } "interact_err: from stderr";

    close($TO_STDIN);
    close($FROM_STDERR);

    diag Dumper([ $pid, $TO_STDIN, $FROM_STDERR ]) if $DEBUG;
}

# complex interactivity to STDERR/STDOUT
{
    local $SIG{CHLD} = 'IGNORE';

    my ($pid1, $TO_STDIN, $pid2, $FROM_STDOUT, $FROM_STDERR) = &{
        exe +{ stdin => 1 }, sub { "2>&1" }, @{ $filt_err_1->[0] },
        exe +{ stdout => 1, stderr => 1 }, @{ $filt_err_out->[0] },
    };

    ok( defined($pid1), "interact_err_out: filt_err_1 pid");
    ok( defined($pid2), "interact_err_out: filt_err_out pid");

    print $TO_STDIN "$_\n" for qw(line1 line2 line3);

    my @expected =
      map { $filt_err_out->[1] . $_ }
      map { $filt_err_1->[1] . $_ }
      @{ $gen_out->[1] };

    timeout {
        my @result_out;
        push(@result_out, scalar <$FROM_STDOUT>) for 1 .. 3;
        s/[\r\n]*\z// for @result_out; # chomp(@result_out);

        is_deeply(\@result_out, \@expected, $_[0]);
    } "interact_err_out: from stdout";

    timeout {
        my @result_err;
        push(@result_err, scalar <$FROM_STDERR>) for 1 .. 3;
        s/[\r\n]*\z// for @result_err; # chomp(@result_err);

        is_deeply(\@result_err, \@expected, $_[0]);
    } "interact_err_out: from stderr";

    close($TO_STDIN);
    close($FROM_STDOUT);
    close($FROM_STDERR);

    diag Dumper([ $pid1, $TO_STDIN, $pid2, $FROM_STDOUT, $FROM_STDERR ]) if $DEBUG;
}

# background
SKIP: {
    skip("- background: only available in DEBUG mode", 4) unless $DEBUG;

    ($?, $!, $^E) = (55, 66, 66);

    # this is touchy - may fail sporadically depending on system load
    # time is not enough for exe() to complete
    #   but with bg() added, it should pass because of no wait
    timeout {
        &{ bg exe $^X, '-e', 'sleep 1', };
        pass($_[0]);
    } "background", 50e-3;

    # error variables are untouched
    is($?     , 55, "bg_no_exit: exit status \$?");
    is($!  + 0, 66, "bg_no_exit: exit status \$!");
    is($^E + 0, 66, "bg_no_exit: exit status \$^E");
}

