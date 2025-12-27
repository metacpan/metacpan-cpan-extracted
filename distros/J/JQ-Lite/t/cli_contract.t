use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);

# Allow overriding the binary path:
#   JQ_LITE_BIN=jq-lite prove -lv t/cli_contract.t
my $BIN = $ENV{JQ_LITE_BIN} || 'bin/jq-lite';

sub run_cmd {
    my (%opt) = @_;
    my $stdin = defined $opt{stdin} ? $opt{stdin} : '';
    my @cmd   = @{ $opt{cmd} };

    my $err = gensym;
    my ($in, $out);

    my $pid = eval { open3($in, $out, $err, @cmd) };
    if ($@) {
        return {
            rc  => 5,
            out => '',
            err => "[USAGE] failed to exec: $@",
        };
    }

    # write stdin
    if (defined $stdin && length $stdin) {
        print {$in} $stdin;
    }
    close $in;

    # slurp stdout / stderr
    local $/;
    my $stdout = <$out>;
    $stdout = '' unless defined $stdout;
    close $out;

    my $stderr = <$err>;
    $stderr = '' unless defined $stderr;
    close $err;

    waitpid($pid, 0);
    my $rc = ($? >> 8);

    return {
        rc  => $rc,
        out => $stdout,
        err => $stderr,
    };
}

sub assert_err_contract {
    my (%a) = @_;
    my $res    = $a{res};
    my $rc     = $a{rc};
    my $prefix = $a{prefix};
    my $name   = $a{name};

    is($res->{rc}, $rc, "$name: exit=$rc");
    like($res->{err}, qr/^\Q$prefix\E/m, "$name: stderr prefix $prefix");
    is($res->{out}, '', "$name: stdout empty on error");
}

# ============================================================
# Exit codes + stderr prefixes
# ============================================================

# Compile error
# NOTE(TODO): Current jq-lite reads input before compile; provide stdin
{
    my $res = run_cmd(cmd => [$BIN, '.['], stdin => "{}\n");
    assert_err_contract(
        res    => $res,
        rc     => 2,
        prefix => '[COMPILE]',
        name   => 'compile error',
    );
}

# Compile error: empty filter segment
{
    my $res = run_cmd(cmd => [$BIN, '.foo |'], stdin => "{}\n");
    assert_err_contract(
        res    => $res,
        rc     => 2,
        prefix => '[COMPILE]',
        name   => 'compile error: empty filter segment',
    );
}

# Runtime error
{
    my $res = run_cmd(
        cmd   => [$BIN, '.x + 1'],
        stdin => qq|{"x":"a"}\n|,
    );
    assert_err_contract(
        res    => $res,
        rc     => 3,
        prefix => '[RUNTIME]',
        name   => 'runtime error',
    );
}

# Runtime error: keys on scalar
{
    my $res = run_cmd(
        cmd   => [$BIN, 'keys'],
        stdin => qq|null\n|,
    );
    assert_err_contract(
        res    => $res,
        rc     => 3,
        prefix => '[RUNTIME]',
        name   => 'runtime error: keys on scalar',
    );
}

# Input error
{
    my $res = run_cmd(
        cmd   => [$BIN, '.'],
        stdin => qq|{broken}\n|,
    );
    assert_err_contract(
        res    => $res,
        rc     => 4,
        prefix => '[INPUT]',
        name   => 'input error',
    );
}

# Usage error: invalid --argjson
{
    my $res = run_cmd(
        cmd => [$BIN, '--argjson', 'x', '{broken}', '.'],
    );
    assert_err_contract(
        res    => $res,
        rc     => 5,
        prefix => '[USAGE]',
        name   => 'usage error: invalid --argjson',
    );
}

# Usage error: unknown option
{
    my $res = run_cmd(cmd => [$BIN, '--bogus-option']);
    assert_err_contract(
        res    => $res,
        rc     => 5,
        prefix => '[USAGE]',
        name   => 'usage error: unknown option',
    );
    like(
        $res->{err},
        qr/\[USAGE\]Unknown option: bogus-option\b/,
        'usage error: unknown option message is prefixed and concise'
    );
}

# ============================================================
# -e / --exit-status semantics
# ============================================================

# -e false => exit 1
{
    my $res = run_cmd(
        cmd   => [$BIN, '-e', '.'],
        stdin => "false\n",
    );
    is($res->{rc}, 1, '-e false => exit 1');
    like($res->{out}, qr/^false\b/m, '-e false => stdout contains false');
    like($res->{err}, qr/^\s*\z/s, '-e false => stderr empty');
}

# -e null => exit 1
{
    my $res = run_cmd(
        cmd   => [$BIN, '-e', '.'],
        stdin => "null\n",
    );
    is($res->{rc}, 1, '-e null => exit 1');
    like($res->{out}, qr/^null\b/m, '-e null => stdout contains null');
    like($res->{err}, qr/^\s*\z/s, '-e null => stderr empty');
}

# -e empty output => exit 1
{
    my $res = run_cmd(
        cmd   => [$BIN, '-e', 'empty'],
        stdin => "1\n",
    );
    is($res->{rc}, 1, '-e empty => exit 1');
    is($res->{out}, '', '-e empty => no stdout');
    like($res->{err}, qr/^\s*\z/s, '-e empty => stderr empty');
}

# -e truthy values (CURRENT behavior: 0 is falsey)
{
    my $res = run_cmd(
        cmd   => [$BIN, '-e', '.'],
        stdin => "0\n",
    );
    is($res->{rc}, 1, '-e 0 => exit 1 (CURRENT BEHAVIOR; TODO fix truthiness)');
    like($res->{out}, qr/^0\b/m, '-e 0 => stdout contains 0');
    like($res->{err}, qr/^\s*\z/s, '-e 0 => stderr empty');
}

# ============================================================
# --arg / --argjson semantics
# ============================================================

# --arg binds string
{
    my $res = run_cmd(
        cmd   => [$BIN, '--arg', 'greeting', 'hello', '$greeting'],
        stdin => "{}\n",
    );
    is($res->{rc}, 0, '--arg string => exit 0');
    like($res->{out}, qr/"hello"/, '--arg string => output "hello"');
    like($res->{err}, qr/^\s*\z/s, '--arg string => stderr empty');
}

# --argjson allows scalar JSON
# NOTE(TODO): stdin is provided to avoid premature INPUT error
{
    my $res = run_cmd(
        cmd   => [$BIN, '--argjson', 'x', '1', '$x'],
        stdin => "null\n",
    );
    is($res->{rc}, 0, '--argjson scalar => exit 0');
    like($res->{out}, qr/^1\b/m, '--argjson scalar => output 1');
    like($res->{err}, qr/^\s*\z/s, '--argjson scalar => stderr empty');
}

# ============================================================
# Broken pipe (SIGPIPE / EPIPE)
# ============================================================

{
    # Finite input to avoid hanging, but still trigger early pipe close
    my $cmd = "yes '{}' | head -n 2000 | $BIN '.' 2>/dev/null | head -n 1 >/dev/null";
    my $rc = system('sh', '-c', $cmd);
    $rc = ($rc >> 8);

    ok(
        $rc == 0 || $rc == 1,
        "broken pipe is not fatal (exit=$rc)",
    );
}

done_testing();
