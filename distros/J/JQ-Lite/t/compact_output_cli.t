use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);

my $json = <<'JSON';
{
  "users": [
    {
      "name": "Alice",
      "age": 30,
      "profile": {
        "active": true,
        "country": "US"
      }
    }
  ]
}
JSON

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, 'bin/jq-lite', '-c', '.users[0]');
print {$in} $json;
close $in;

my $stdout = do { local $/; <$out> } // '';
my $stderr = do { local $/; <$err> } // '';

waitpid($pid, 0);

is(
    $stdout,
    "{\"age\":30,\"name\":\"Alice\",\"profile\":{\"active\":true,\"country\":\"US\"}}\n",
    'compact-output emits single-line JSON with trailing newline'
);
like($stderr, qr/^\s*\z/, 'no warnings emitted when using -c');

my $exit = $? >> 8;
is($exit, 0, 'process exits successfully');

done_testing;
