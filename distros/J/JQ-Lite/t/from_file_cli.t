use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Cwd qw(abs_path);

# 仮想ワークディレクトリ（掃除はTempのライフサイクル任せ）
my $tmpdir = tempdir(CLEANUP => 1);

# フィルタファイル
my ($fh_filter, $filter_path) = tempfile(DIR => $tmpdir, UNLINK => 1);
print {$fh_filter} ".users[]\n";
close $fh_filter;

# 入力JSON（テストが期待する内容をここに書く）
my ($fh_users, $users_path) = tempfile(DIR => $tmpdir, UNLINK => 1);
print {$fh_users} <<'JSON';
{
  "users": [
    {"name":"Alice","age":30,"profile":{"active":true,"country":"US"}},
    {"name":"Bob","age":25,"profile":{"active":false,"country":"JP"}}
  ]
}
JSON
close $fh_users;

# 実行ファイルは絶対パスで
use FindBin;
my $exe = abs_path(File::Spec->catfile($FindBin::Bin, '..', 'bin', 'jq-lite'));

my $err = gensym;
my $pid = open3(my $in, my $out, $err,
    $^X, $exe, '-c', '--from-file', $filter_path, $users_path);
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';
waitpid($pid, 0);
my $exit_code = $? >> 8;

is($stdout, qq({"age":30,"name":"Alice","profile":{"active":true,"country":"US"}}\n{"age":25,"name":"Bob","profile":{"active":false,"country":"JP"}}\n),
   'filters loaded from files emit expected JSON');
like($stderr, qr/^\s*\z/, 'no warnings emitted when using --from-file');
is($exit_code, 0, 'process exits successfully with --from-file');

done_testing;
