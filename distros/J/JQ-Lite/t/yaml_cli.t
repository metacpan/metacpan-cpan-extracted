use strict;
use warnings;
use Test::More;

# YAML support relies on functionality available only in Perl 5.40 and newer
if ($] < 5.040000) {
    plan skip_all => "YAML tests require Perl 5.40 or newer";
}

use IPC::Open3;
use Symbol qw(gensym);
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Cwd qw(abs_path);
use FindBin;

# Create a temporary directory for test files
my $tmpdir = tempdir(CLEANUP => 1);

# Create a temporary YAML file
my ($fh_yaml, $yaml_path) = tempfile(DIR => $tmpdir, SUFFIX => '.yaml', UNLINK => 1);
print {$fh_yaml} <<'YAML';
users:
  - name: Alice
    age: 30
  - name: Bob
    age: 25
YAML
close $fh_yaml;

# Determine the path to the jq-lite executable
my $exe = abs_path(File::Spec->catfile($FindBin::Bin, '..', 'bin', 'jq-lite'));

# --- Test 1: Read YAML file automatically by extension ---
my $err = gensym;
my $pid = open3(my $in, my $out, $err,
    $^X, $exe, '.users[].name', $yaml_path);
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';
waitpid($pid, 0);
my $exit_code = $? >> 8;

is($stdout, qq("Alice"\n"Bob"\n), 'YAML files are auto-detected by extension');
like($stderr, qr/^\s*\z/, 'no warnings emitted when reading YAML file');
is($exit_code, 0, 'process exits successfully when reading YAML file');

# --- Test 2: Read YAML from STDIN with --yaml flag ---
my $err2 = gensym;
my $pid2 = open3(my $in2, my $out2, $err2,
    $^X, $exe, '--yaml', '.users | length');
print {$in2} <<'YAML';
users:
  - name: Carol
  - name: Dave
YAML
close $in2;

my $stdout2 = do { local $/; <$out2> } // '';
my $stderr2 = do { local $/; <$err2> } // '';
waitpid($pid2, 0);
my $exit_code2 = $? >> 8;

is($stdout2, "2\n", '--yaml flag decodes YAML piped via STDIN');
like($stderr2, qr/^\s*\z/, 'no warnings emitted when using --yaml from STDIN');
is($exit_code2, 0, 'process exits successfully when parsing YAML from STDIN');

done_testing;
