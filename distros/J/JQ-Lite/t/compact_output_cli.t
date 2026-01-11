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

my $array_json = "[10]\n";
my $array_err  = gensym;
my $array_pid  = open3(my $array_in, my $array_out, $array_err, $^X, 'bin/jq-lite', '-c', '.[0]');
print {$array_in} $array_json;
close $array_in;

my $array_stdout = do { local $/; <$array_out> } // '';
my $array_stderr = do { local $/; <$array_err> } // '';

waitpid($array_pid, 0);

is($array_stdout, "10\n", 'array indexing emits the indexed element in compact output');
like($array_stderr, qr/^\s*\z/, 'no warnings emitted when indexing arrays with -c');

my $array_exit = $? >> 8;
is($array_exit, 0, 'array indexing process exits successfully');

done_testing;
