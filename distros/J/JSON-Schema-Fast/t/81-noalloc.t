use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;

# The valid path must not grow the heap (principle 1). Author-only: RSS delta
# over many validates is a portable regression guard (a malloc-count shim would
# be tighter but platform-specific). is_valid on a valid document, and the
# error path on an invalid one, must both stay flat across runs.
plan skip_all => 'author test (set AUTHOR_TESTING=1)'
    unless $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};
plan skip_all => 'RSS probe needs ps' unless `ps -o rss= -p $$ 2>/dev/null` =~ /\d/;

sub rss { my $r = `ps -o rss= -p $$`; $r =~ s/\s+//g; $r }

my $v = JSON::Schema::Fast->compile({
    type       => 'object', required => ['name'],
    properties => { name => { type => 'string', minLength => 1 },
                    age  => { type => 'integer', minimum => 0 },
                    tags => { type => 'array', items => { type => 'string' }, uniqueItems => 1 } },
});
my $good = File::Raw::JSON::file_json_decode('{"name":"a","age":1,"tags":["x","y"]}');
my $bad  = File::Raw::JSON::file_json_decode('{"age":-1,"tags":["x","x"]}');

$v->is_valid($good), $v->errors($bad) for 1 .. 5000;   # warm + fill freelists

my $a = rss();
$v->is_valid($good) for 1 .. 300_000;
my $b = rss();
$v->errors($bad) for 1 .. 300_000;
my $c = rss();

cmp_ok($b - $a, '<=', 8, 'valid path does not grow RSS');
cmp_ok($c - $b, '<=', 8, 'error path is leak-clean');
diag("rss valid: ${a}->${b} KB   error: ${b}->${c} KB");

done_testing;
