use strict;
use warnings;
use Test::More;
use Config;
use File::Temp ();

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

# TDLib answers an unknown @type with a clean error, but silently ignores an
# unknown field on a request it recognises. So a mistyped or renamed field
# name is the one schema mistake nothing reports: not TDLib, not the
# callback, not the existing author checks. This runs the whole suite with
# every outgoing request's field names checked against the pinned catalogue.

my @tests = sort glob 't/*.t';
cmp_ok scalar(@tests), '>', 40, 'the scan found test files to run';

my ($total, $funcs, $nested, @bad, $files_done) = (0, 0, 0);
for my $t (@tests) {
    my $out = `"$Config{perlpath}" -Iblib/lib -Iblib/arch -Ixt/lib -MValidateFields $t 2>&1 >/dev/null`;
    push @bad, "$t: $1" while $out =~ /FIELD-NAMES-BAD: (.+)/g;
    if ($out =~ /FIELD-NAMES-DONE (\d+) (\d+) (\d+)/) {
        $total += $1;
        $funcs  = $2 if $2 > $funcs;
        $nested = $3 if $3 > $nested;
        $files_done++;
    }
}

is $files_done, scalar(@tests), 'every file ran the check to completion';

# the check reports by absence, so its silence must not read as a pass
cmp_ok $total, '>', 300, 'the run exercised a substantial number of requests';
cmp_ok $nested, '>', 20, 'and reached the nested objects inside them';

is_deeply \@bad, [],
    'every field name the module emits exists on that function in the schema';
diag $_ for @bad;
diag "checked $total requests across $files_done files";

done_testing;
