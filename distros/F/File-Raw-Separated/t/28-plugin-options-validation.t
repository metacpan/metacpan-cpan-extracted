use strict;
use warnings;
use Test::More;
use File::Raw::Separated;
use File::Raw qw(slurp);

# Validation lives in the plugin's READ phase: decode_opts() walks the
# per-call options HV and croaks on any unknown key (catches typos like
# 'seperator'). No module-wide options table to mutate; each call's
# validation is its own thing.

# Unknown key croaks
my $rc = eval {
    File::Raw::slurp('t/data/simple.csv',
        plugin    => 'csv',
        seperator => ';',         # typo
    );
    1;
};
ok(!$rc, "unknown option key croaks");
like($@, qr/unknown option/i, 'error tagged "unknown option"');
like($@, qr/seperator/,       'error names the bad key');

# Bad eol value croaks (decode_opts validates the enum)
$rc = eval {
    File::Raw::slurp('t/data/simple.csv',
        plugin => 'csv',
        eol    => 'bogus',
    );
    1;
};
ok(!$rc, "bad eol value croaks");
like($@, qr/eol/i, 'error mentions eol');
like($@, qr/auto|lf|crlf|cr/i, 'error lists accepted eol values');

# Validation happens BEFORE the plugin sees the options - so a bad
# follow-up call doesn't poison anything for the next good call.
my $rows = File::Raw::slurp('t/data/simple.csv', plugin => 'csv');
is_deeply($rows, [['a','b','c'], ['d','e','f']],
    'next good call works (no state was tainted by the failed one)');

done_testing;
