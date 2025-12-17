use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);

my $json = <<'JSON';
{
  "text": "こんにちは",
  "nested": {"emoji": "😀"}
}
JSON

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, 'bin/jq-lite', '-a', '-c', '.');
print {$in} $json;
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';

waitpid($pid, 0);

is(
    $stdout,
    "{\"nested\":{\"emoji\":\"\\ud83d\\ude00\"},\"text\":\"\\u3053\\u3093\\u306b\\u3061\\u306f\"}\n",
    'ascii-output escapes non-ASCII characters',
);
like($stderr, qr/^\s*\z/, 'no warnings emitted when using -a');

my $exit = $? >> 8;
is($exit, 0, 'process exits successfully');

done_testing;
