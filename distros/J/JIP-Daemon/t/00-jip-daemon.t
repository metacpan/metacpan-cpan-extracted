#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec;
use Carp qw(croak);
use English qw(-no_match_vars);
use Mock::Quick qw(qtakeover qobj qmeth);
use Capture::Tiny qw(capture capture_stderr);

plan tests => 16;

subtest 'Require some module' => sub {
    plan tests => 2;

    use_ok 'JIP::Daemon', '0.041';
    require_ok 'JIP::Daemon';

    diag(
        sprintf 'Testing JIP::Daemon %s, Perl %s, %s',
            $JIP::Daemon::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'new(). exceptions' => sub {
    plan tests => 20;

    eval { JIP::Daemon->new(uid => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "uid"}x;
    };
    eval { JIP::Daemon->new(uid => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "uid"}x;
    };

    eval { JIP::Daemon->new(gid => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "gid"}x;
    };
    eval { JIP::Daemon->new(gid => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "gid"}x;
    };

    eval { JIP::Daemon->new(cwd => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "cwd"}x;
    };
    eval { JIP::Daemon->new(cwd => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "cwd"}x;
    };

    eval { JIP::Daemon->new(umask => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "umask"}x;
    };
    eval { JIP::Daemon->new(umask => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "umask"}x;
    };

    eval { JIP::Daemon->new(logger => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "logger"}x;
    };
    eval { JIP::Daemon->new(logger => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "logger"}x;
    };

    eval { JIP::Daemon->new(log_callback => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "log_callback"}x;
    };
    eval { JIP::Daemon->new(log_callback => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "log_callback"}x;
    };

    eval { JIP::Daemon->new(on_fork_callback => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "on_fork_callback"}x;
    };
    eval { JIP::Daemon->new(on_fork_callback => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "on_fork_callback"}x;
    };

    eval { JIP::Daemon->new(stdout => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "stdout"}x;
    };
    eval { JIP::Daemon->new(stdout => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "stdout"}x;
    };

    eval { JIP::Daemon->new(stderr => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "stderr"}x;
    };
    eval { JIP::Daemon->new(stderr => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "stderr"}x;
    };

    eval { JIP::Daemon->new(program_name => undef) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "program_name"}x;
    };
    eval { JIP::Daemon->new(program_name => q{}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "program_name"}x;
    };
};

subtest 'new()' => sub {
    plan tests => 17;

    my $obj = JIP::Daemon->new;
    ok $obj, 'got instance if JIP::Daemon';

    isa_ok $obj, 'JIP::Daemon';

    can_ok $obj, qw(
        new
        daemonize
        reopen_std
        drop_privileges
        try_kill
        status
        pid
        uid
        gid
        cwd
        umask
        logger
        dry_run
        is_detached
        log_callback
        on_fork_callback
        devnull
        stdout
        stderr
        program_name
    );

    is $obj->pid,              $PROCESS_ID;
    is $obj->dry_run,          0;
    is $obj->is_detached,      0;
    is $obj->uid,              undef;
    is $obj->gid,              undef;
    is $obj->cwd,              undef;
    is $obj->umask,            undef;
    is $obj->logger,           undef;
    is $obj->on_fork_callback, undef;
    is $obj->devnull,          File::Spec->devnull;
    is $obj->stdout,           undef;
    is $obj->stderr,           undef;
    is $obj->program_name,     $PROGRAM_NAME;

    is ref $obj->log_callback, 'CODE';
};

subtest 'logging' => sub {
    plan tests => 2;

    my $logs = [];
    my $obj  = JIP::Daemon->new(logger => qobj(
        info => qmeth {
            my $self = shift;
            push @{ $logs }, @ARG;
        },
    ));

    is ref($obj->_log()), 'JIP::Daemon';
    $obj->_log('simple string');
    $obj->_log('format %s', 'value');

    # if logger is not defined
    $obj = JIP::Daemon->new;
    $obj->_log('another simple string');
    $obj->_log('another format %s', 'value');

    is_deeply $logs, ['simple string', 'format value'];
};

subtest 'try_kill()' => sub {
    plan tests => 6;

    my $control = qtakeover 'POSIX' => (
        kill => sub {
            my ($pid, $signal) = @ARG;
            is_deeply [$pid, $signal], [$PROCESS_ID, q{9}];
            return 1;
        },
    );
    is(JIP::Daemon->new->try_kill(q{9}), 1);
    $control->restore('kill');

    $control->override(kill => sub {
        my ($pid, $signal) = @ARG;
        is_deeply [$pid, $signal], [$PROCESS_ID, q{0}];
        return 1;
    });
    is(JIP::Daemon->new->try_kill, 1);
    $control->restore('kill');

    my $std_err = capture_stderr {
        my $control_daemon = qtakeover 'JIP::Daemon' => (pid => sub { undef });

        is(JIP::Daemon->new->try_kill(q{0}), undef);
    };
    like $std_err, qr{^No \s subprocess \s running}x;
};

subtest 'status()' => sub {
    plan tests => 2;

    my $control = qtakeover 'POSIX' => (
        kill => sub {
            my ($pid, $signal) = @ARG;
            is_deeply [$pid, $signal], [$PROCESS_ID, 0];
            return 1;
        },
    );

    is_deeply [JIP::Daemon->new->status], [$PROCESS_ID, 1, 0];
};

subtest 'drop_privileges()' => sub {
    plan tests => 9;

    my $logs       = [];
    my $empty_logs = sub { $logs = []; };

    my $cb = sub {
        my $self = shift;
        push @{ $logs }, @ARG;
    };

    {
        my $uid = '65534';

        my $control = qtakeover 'POSIX' => (setuid => sub {
            is $ARG[0], $uid;
            return 1;
        });

        is(
            ref JIP::Daemon->new(uid => $uid, log_callback => $cb)->drop_privileges,
            'JIP::Daemon',
        );
        is_deeply $logs, ['Set uid=%d', $uid];

        $empty_logs->();
    }
    {
        my $gid = '65534';

        my $control = qtakeover 'POSIX' => (setgid => sub {
            is $ARG[0], $gid;
            return 1;
        });

        JIP::Daemon->new(gid => $gid, log_callback => $cb)->drop_privileges;
        is_deeply $logs, ['Set gid=%d', $gid];

        $empty_logs->();
    }
    {
        my $umask = 0;

        my $control = qtakeover 'POSIX' => (umask => sub {
            is $ARG[0], $umask;
            return 1;
        });

        JIP::Daemon->new(umask => $umask, log_callback => $cb)->drop_privileges;
        is_deeply $logs, ['Set umask=%s', $umask];

        $empty_logs->();
    }
    {
        my $cwd = q{/};

        my $control = qtakeover 'POSIX' => (chdir => sub {
            is $ARG[0], $cwd;
            return 1;
        });

        JIP::Daemon->new(cwd => $cwd, log_callback => $cb)->drop_privileges;
        is_deeply $logs, ['Set cwd=%s', $cwd];

        $empty_logs->();
    }
};

subtest 'exceptions in drop_privileges()' => sub {
    plan tests => 4;

    my $control = qtakeover 'POSIX' => (
        setuid => sub { 0 },
        setgid => sub { 0 },
        umask  => sub { 0 },
        chdir  => sub { 0 },
    );

    eval { JIP::Daemon->new(uid => 1)->drop_privileges } or do {
        like $EVAL_ERROR, qr{^Can't \s set \s uid \s "1":}x;
    };
    eval { JIP::Daemon->new(gid => 2)->drop_privileges } or do {
        like $EVAL_ERROR, qr{^Can't \s set \s gid \s "2":}x;
    };
    eval { JIP::Daemon->new(umask => 3)->drop_privileges } or do {
        like $EVAL_ERROR, qr{^Can't \s set \s umask \s "3":}x;
    };
    eval { JIP::Daemon->new(cwd => q{/})->drop_privileges } or do {
        like $EVAL_ERROR, qr{^Can't \s chdir \s to \s "/":}x;
    };
};

subtest 'reopen_std()' => sub {
    plan tests => 4;

    my $obj = JIP::Daemon->new;
    is ref($obj), 'JIP::Daemon';

    my ($stdout, $stderr) = capture {
        print {*STDOUT} q{first stdout msg}
            or croak(sprintf q{Can't print to STDOUT: %s}, $OS_ERROR);
        print {*STDERR} q{first stderr msg}
            or croak(sprintf q{Can't print to STDERR: %s}, $OS_ERROR);

        is ref($obj->reopen_std), 'JIP::Daemon';

        print {*STDOUT} q{second stdout msg}
            or croak(sprintf q{Can't print to STDOUT: %s}, $OS_ERROR);
        print {*STDERR} q{second stderr msg}
            or croak(sprintf q{Can't print to STDERR: %s}, $OS_ERROR);
    };

    is $stdout, q{first stdout msg};
    is $stderr, q{first stderr msg};
};

subtest 'change_program_name. nothing to do' => sub {
    plan tests => 2;

    my $logs = [];

    my $control_daemon = qtakeover 'JIP::Daemon' => (
        logger => qobj(info => qmeth {
            my ($self, $msg) = @ARG;
            push @{ $logs }, $msg;
        }),
    );

    my $old_program_name = $PROGRAM_NAME;

    my $obj = JIP::Daemon->new->change_program_name;

    my $new_program_name = $PROGRAM_NAME;

    is $old_program_name, $new_program_name;
    is_deeply $logs, [];
};

subtest 'change_program_name' => sub {
    plan tests => 4;

    my $logs = [];

    my $control_daemon = qtakeover 'JIP::Daemon' => (
        logger => qobj(info => qmeth {
            my ($self, $msg) = @ARG;
            push @{ $logs }, $msg;
        }),
    );

    my $old_program_name = $PROGRAM_NAME;
    my $new_program_name = 'tratata';

    my $obj = JIP::Daemon->new(program_name => $new_program_name);
    $obj = $obj->change_program_name;

    is $PROGRAM_NAME, $new_program_name;
    is_deeply $logs, [
        'The program name changed from t/00-jip-daemon.t to tratata',
    ];

    $obj = JIP::Daemon->new(program_name => $old_program_name);
    $obj = $obj->change_program_name;

    is $PROGRAM_NAME, $old_program_name;
    is_deeply $logs, [
        'The program name changed from t/00-jip-daemon.t to tratata',
        'The program name changed from tratata to t/00-jip-daemon.t',
    ];
};

subtest 'daemonize. dry_run' => sub {
    plan tests => 4;

    my $control_daemon = qtakeover 'JIP::Daemon' => (
        drop_privileges => sub {
            my $proc = shift;
            pass 'drop_privileges() method is invoked';
            return $proc;
        },
    );

    my $obj = JIP::Daemon->new(dry_run => 1)->daemonize;
    is_deeply [$obj->is_detached, $obj->pid], [0, $PROCESS_ID];

    $obj->daemonize;
    is_deeply [$obj->is_detached, $obj->pid], [0, $PROCESS_ID];
};

subtest 'daemonize. parent' => sub {
    plan tests => 7;

    my $pid  = '500';
    my $logs = [];

    my $control_posix = qtakeover 'POSIX' => (
        fork => sub {
            pass 'fork() method is invoked';
            return $pid;
        },
        exit => sub {
            pass 'fork() method is invoked';
            my $exit_status = shift;
            is $exit_status, 0;
        },
    );
    my $control_daemon = qtakeover 'JIP::Daemon' => (
        logger => qobj(info => qmeth {
            my ($self, $msg) = @ARG;
            push @{ $logs }, $msg;
        }),
        drop_privileges => sub {
            my $self = shift;
            pass 'drop_privileges() method is invoked';
            return $self;
        },
    );

    my $obj = JIP::Daemon->new->daemonize;
    is_deeply [$obj->is_detached, $obj->pid], [1, $pid];

    # daemonize on detached process changes nothing
    $obj->daemonize;
    is_deeply [$obj->is_detached, $obj->pid], [1, $pid];
    is_deeply $logs, [
        'Daemonizing the process',
        'Spawned process pid=500. Parent exiting',
    ];
};

subtest 'daemonize. child' => sub {
    plan tests => 9;

    my $pid  = '500';
    my $logs = [];

    my $control_posix = qtakeover 'POSIX' => (
        fork => sub {
            pass 'fork() method is invoked';
            return 0;
        },
        setsid => sub {
            pass 'setsid() method is invoked';
            return 1;
        },
        getpid => sub {
            pass 'getpid() method is invoked';
            return $pid;
        },
    );
    my $control_daemon = qtakeover 'JIP::Daemon' => (
        logger => qobj(info => qmeth {
            my ($self, $msg) = @ARG;
            push @{ $logs }, $msg;
        }),
        reopen_std => sub {
            my $self = shift;
            pass 'reopen_std() method is invoked';
            return $self;
        },
        drop_privileges => sub {
            my $self = shift;
            pass 'drop_privileges() method is invoked';
            return $self;
        },
        change_program_name => sub {
            my $self = shift;
            pass 'change_program_name() method is invoked';
            return $self;
        },
    );

    my $obj = JIP::Daemon->new->daemonize;
    is_deeply [$obj->is_detached, $obj->pid], [1, $pid];

    # daemonize on detached process changes nothing
    $obj->daemonize;
    is_deeply [$obj->is_detached, $obj->pid], [1, $pid];
    is_deeply $logs, ['Daemonizing the process'];
};

subtest 'daemonize. exceptions' => sub {
    plan tests => 6;

    my $logs = [];

    my $control_daemon = qtakeover 'JIP::Daemon' => (
        logger => qobj(info => qmeth {
            my ($self, $msg) = @ARG;
            push @{ $logs }, $msg;
        }),
    );
    my $control_posix = qtakeover 'POSIX' => (
        fork => sub {
            pass 'fork() method is invoked';
            return;
        },
    );
    eval { JIP::Daemon->new->daemonize } or do {
        like $EVAL_ERROR, qr{^Can't \s fork}x;
    };
    $control_posix->restore('fork');

    $control_posix->override(
        fork => sub {
            pass 'fork() method is invoked';
            return 0;
        },
        setsid => sub {
            pass 'setsid() method is invoked';
            return;
        },
    );
    eval { JIP::Daemon->new->daemonize } or do {
        like $EVAL_ERROR, qr{^Can't \s start \s a \s new \s session:}x;
    };
    is_deeply $logs, ['Daemonizing the process', 'Daemonizing the process'];
};

subtest 'daemonize. "on_fork_callback"' => sub {
    plan tests => 4;

    my $control_posix = qtakeover 'POSIX' => (
        fork => sub {
            pass 'fork() method is invoked';
            return $PROCESS_ID; # parent process
        },
        exit => sub {
            pass 'exit() method is invoked';
        },
    );

    JIP::Daemon->new(on_fork_callback => sub {
        pass '"on_fork_callback" is invoked';

        my $proc = shift;
        is ref($proc), 'JIP::Daemon';
    })->daemonize;
};

