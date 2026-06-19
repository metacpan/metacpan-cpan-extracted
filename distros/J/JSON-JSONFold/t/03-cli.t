use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);
use JSON::PP qw(decode_json);

my $cmd = "$^X -Iblib/lib blib/script/jsonfold.pl";
my $json = '{"b":[1,2,3],"a":{"x":1}}';

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $cmd);
print {$in} $json;
close $in;

my $got = do { local $/; <$out> };
my $stderr = do { local $/; <$err> };
waitpid($pid, 0);

is($?, 0, 'CLI exits successfully') or diag($stderr);
is_deeply(decode_json($got), decode_json($json), 'CLI output round-trips');

done_testing;
