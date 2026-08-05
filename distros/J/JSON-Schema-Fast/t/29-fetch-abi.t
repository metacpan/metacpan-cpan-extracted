use strict; use warnings;
use Test::More;

# The default resolver fetches remote $ref documents through Fetch's C ABI.
# Opt-in and online-only, so it never runs on smokers or offline:
#   JSF_ONLINE=1 prove -blv t/29-fetch-abi.t
plan skip_all => 'set JSF_ONLINE=1 to run the live Fetch-ABI test' unless $ENV{JSF_ONLINE};
plan skip_all => 'Fetch not installed' unless eval { require Fetch; 1 };

use JSON::Schema::Fast;

# no resolver -> the $ref auto-fetches the draft 2020-12 meta-schema via the
# Fetch ABI; validating schema-shaped data against it exercises the whole path
# (fetch + the full dialect: $dynamicRef, unevaluated*, $vocabulary).
my $v = eval { JSON::Schema::Fast->compile({ '$ref' => 'https://json-schema.org/draft/2020-12/schema' }) };
ok(!$@ && $v, 'remote $ref auto-fetched and compiled via the Fetch ABI') or diag($@);

SKIP: {
    skip 'compile did not produce a validator (offline?)', 2 unless $v;
    ok( $v->is_valid({ type => 'string', minLength => 1 }), 'a valid schema passes the meta-schema');
    ok(!$v->is_valid({ type => 12345 }),                    'an invalid schema fails the meta-schema');
}

# resolver => undef disables auto-fetch (offline, deterministic)
{
    eval { JSON::Schema::Fast->compile({ '$ref' => 'https://example.invalid/x' }, resolver => undef) };
    like($@, qr/cannot resolve/, 'resolver => undef disables remote fetching');
}

done_testing;
