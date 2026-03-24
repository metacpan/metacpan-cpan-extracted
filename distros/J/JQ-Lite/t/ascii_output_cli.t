use strict;
use warnings;
use utf8;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);
use JSON::PP qw(decode_json);

my $json = <<'JSON';
{
  "text": "こんにちは",
  "nested": {"emoji": "😀"}
}
JSON

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, 'bin/jq-lite', '-a', '-c', '.');
binmode($in, ':encoding(UTF-8)');
print {$in} $json;
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';

waitpid($pid, 0);

like(
    $stdout,
    qr/\A\{.*\}\n\z/s,
    'ascii-output emits a single compact JSON line with trailing newline',
);
unlike(
    $stdout,
    qr/[^\x00-\x7F]/,
    'ascii-output does not emit raw non-ASCII characters',
);
is_deeply(
    decode_json($stdout),
    {
        text   => "こんにちは",
        nested => { emoji => "\x{1F600}" },
    },
    'ascii-output preserves the decoded JSON value',
);
like($stderr, qr/^\s*\z/, 'no warnings emitted when using -a');

my $exit = $? >> 8;
is($exit, 0, 'process exits successfully');

done_testing;
