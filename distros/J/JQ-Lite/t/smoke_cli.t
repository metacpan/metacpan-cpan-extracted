use strict;
use warnings;
use Test::More;
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;

# ----------------------------
# Locate jq-lite executable reliably (AUR / make test friendly)
# ----------------------------
sub _is_file {
    my ($p) = @_;
    return defined($p) && -f $p;
}

sub _find_jq_lite {
    # 1) explicit override
    return $ENV{JQ_LITE} if _is_file($ENV{JQ_LITE});

    # 2) Prefer build output (ExtUtils::MakeMaker / Module::Build)
    my @candidates = (
        File::Spec->catfile($FindBin::Bin, '..', 'blib', 'script', 'jq-lite'),
        File::Spec->catfile($FindBin::Bin, '..', 'blib', 'bin',    'jq-lite'),
        File::Spec->catfile($FindBin::Bin, '..', 'script',         'jq-lite'),
        File::Spec->catfile($FindBin::Bin, '..', 'bin',            'jq-lite'),
    );

    for my $p (@candidates) {
        return $p if _is_file($p);
    }

    # 3) Fall back to PATH
    return 'jq-lite';
}

my $JQ = _find_jq_lite();

# Execute via perl to avoid shebang/exec-bit issues in build/chroot envs
my @JQ_CMD = ($^X, $JQ);

# If jq-lite still isn't found, provide a helpful skip (optional but nice for builders)
# Comment this out if you prefer hard failures when PATH is missing.
if ($JQ eq 'jq-lite') {
    # If PATH does not contain jq-lite during 'make test', this would fail anyway.
    # We keep tests running to surface a clear error message from open3.
    # plan skip_all => "jq-lite executable not found (set JQ_LITE=... or ensure blib/script/jq-lite exists)";
}

# ----------------------------
# Helpers
# ----------------------------
sub run_cmd {
    my (@cmd) = @_;

    my $err = gensym();
    my $pid = open3(my $in, my $out, $err, @cmd);

    close $in;

    local $/ = undef;
    my $stdout = <$out>;
    my $stderr = <$err>;

    close $out;
    close $err;

    waitpid($pid, 0);
    my $exit = $? >> 8;

    $stdout = '' unless defined $stdout;
    $stderr = '' unless defined $stderr;

    return ($exit, $stdout, $stderr);
}

sub run_ok {
    my (%args) = @_;
    my $name   = $args{name};
    my $filter = $args{filter};     # filter string (single arg)
    my $file   = $args{file};       # optional filename
    my $opt    = $args{opt} // [];  # arrayref like ['-c']
    my $expect = $args{expect};     # exact expected stdout

    my @cmd = (@JQ_CMD, @$opt, $filter);
    push @cmd, $file if defined $file;

    my ($exit, $stdout, $stderr) = run_cmd(@cmd);

    is($exit, 0, "$name: exit=0")
      or diag("CMD: @cmd\nSTDERR:\n$stderr\nSTDOUT:\n$stdout");

    is($stderr, '', "$name: no stderr")
      or diag("CMD: @cmd\nSTDERR:\n$stderr");

    is($stdout, $expect, "$name: stdout matches")
      or diag("CMD: @cmd\nGOT:\n$stdout\nEXP:\n$expect");
}

# ----------------------------
# Fixtures
# ----------------------------
my $tmpdir = tempdir(CLEANUP => 1);

sub write_file {
    my ($name, $content) = @_;
    my $path = File::Spec->catfile($tmpdir, $name);
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh;
    return $path;
}

my $t1 = write_file('t1.json', qq|{"users":[{"name":"Alice"},{"name":"Bob"}]}\n|);
my $t2 = write_file('t2.json', qq|{"items":[3,1,2]}\n|);
my $t3 = write_file('t3.json', qq|{"obj":{"b":2,"a":1},"arr":[10,20,30],"s":"hi","n":5,"t":true,"f":false,"nullv":null}\n|);
my $t4 = write_file('t4.json', qq|[{"k":2},{"k":1},{"k":3}]\n|);
my $logfile = write_file('logfile.txt', "line1\n\nline2\nline3\n\n");

# ----------------------------
# Tests (CLI smoke)
# ----------------------------

# 1) identity compact
run_ok(
    name   => 'identity compact',
    opt    => ['-c'],
    filter => '.',
    file   => $t2,
    expect => qq|{"items":[3,1,2]}\n|,
);

# 2) field access
run_ok(
    name   => 'field access',
    opt    => ['-c'],
    filter => '.items',
    file   => $t2,
    expect => qq|[3,1,2]\n|,
);

# 3) array index
run_ok(
    name   => 'array index',
    opt    => ['-c'],
    filter => '.items[0]',
    file   => $t2,
    expect => qq|3\n|,
);

# 4) sort + first (synopsis)
run_ok(
    name   => 'sort + first',
    opt    => ['-c'],
    filter => '.items | sort | first',
    file   => $t2,
    expect => qq|1\n|,
);

# 5) users names (multiline stdout)
run_ok(
    name   => 'users names',
    opt    => ['-c'],
    filter => '.users[].name',
    file   => $t1,
    expect => qq|"Alice"\n"Bob"\n|,
);

# 6) raw slurp split (fixed synopsis)
run_ok(
    name   => 'raw slurp split',
    opt    => ['-R', '-s', '-c'],
    filter => 'split("\n")',
    file   => $logfile,
    expect => qq|["line1","","line2","line3","",""]\n|,
);

# 7) length array
run_ok(
    name   => 'length array',
    opt    => ['-c'],
    filter => '.arr | length',
    file   => $t3,
    expect => qq|3\n|,
);

# 8) length object
run_ok(
    name   => 'length object',
    opt    => ['-c'],
    filter => '.obj | length',
    file   => $t3,
    expect => qq|2\n|,
);

# 9) keys object
run_ok(
    name   => 'keys object',
    opt    => ['-c'],
    filter => '.obj | keys',
    file   => $t3,
    expect => qq|["a","b"]\n|,
);

# 10) map add 1
run_ok(
    name   => 'map add 1',
    opt    => ['-c'],
    filter => '.arr | map(. + 1)',
    file   => $t3,
    expect => qq|[11,21,31]\n|,
);

# 11) sort_by .k
run_ok(
    name   => 'sort_by .k',
    opt    => ['-c'],
    filter => 'sort_by(.k) | map(.k)',
    file   => $t4,
    expect => qq|[1,2,3]\n|,
);

done_testing();
