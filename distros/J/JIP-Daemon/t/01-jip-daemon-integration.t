#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use File::Temp ();
use File::Spec;
use Test::More;
use English qw(-no_match_vars);
use Mock::Quick qw(qtakeover qobj qmeth);
use Capture::Tiny qw(capture);

if ($ENV{'TEST_JIP_DAEMON'}) {
    plan tests => 4;
}
else {
    plan skip_all => 'set TEST_JIP_DAEMON to enable this test (developer only!)';
}

subtest 'Require some module' => sub {
    plan tests => 3;

    use_ok 'JIP::Daemon', '0.041';

    require_ok 'JIP::Daemon';
    is $JIP::Daemon::VERSION, '0.041';

    diag(
        sprintf 'Testing JIP::Daemon %s, Perl %s, %s',
            $JIP::Daemon::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'try_kill()' => sub {
    plan tests => 3;

    is(JIP::Daemon->new->try_kill,    1);
    is(JIP::Daemon->new->try_kill(0), 1);

    local $SIG{'USR1'} = sub { pass 'USR1 caught'; };
    JIP::Daemon->new->try_kill(10);
};

subtest 'status()' => sub {
    plan tests => 1;

    is_deeply [JIP::Daemon->new->status], [$PROCESS_ID, 1, 0];
};

subtest 'reopen_std()' => sub {
    plan tests => 8;

    my $stdout_fh = File::Temp->new;
    my $stderr_fh = File::Temp->new;

    my $logs = [];

    my $control_daemon = qtakeover 'JIP::Daemon' => (
        logger => qobj(info => qmeth {
            my ($self, $msg) = @ARG;
            push @{ $logs }, $msg;
        }),
    );

    my $obj = JIP::Daemon->new(
        stdout => q{+>>}. $stdout_fh->filename,
        stderr => q{+>>}. $stderr_fh->filename,
    );

    is $obj->stdout, q{+>>}. $stdout_fh->filename;
    is $obj->stderr, q{+>>}. $stderr_fh->filename;

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

    is slurp($stdout_fh), q{second stdout msg};
    is slurp($stderr_fh), q{second stderr msg};

    is_deeply $logs, [
        'Reopen STDOUT to: '. $obj->stdout,
        'Reopen STDERR to: '. $obj->stderr,
    ];
};

sub slurp {
    my $fh = shift;

    local $INPUT_RECORD_SEPARATOR = undef;
    my $data = <$fh>;

    return $data;
}

