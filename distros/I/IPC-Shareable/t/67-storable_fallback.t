use warnings;
use strict;

use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process require_free_sem_sets);

require_free_sem_sets();
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');

# Tests for the Storable-to-JSON auto-detection fallback:
# When a segment was written with serializer => 'storable' and is later
# re-attached without an explicit serializer (i.e. using the json default),
# IPC::Shareable should detect the mismatch, switch to storable for the
# session, and emit a carp warning.


# -----------------------------------------------------------------------
# Helper: capture warnings into an array
# -----------------------------------------------------------------------
sub capture_warns (&) {
    my $code = shift;
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    $code->();
    return @w;
}

# -----------------------------------------------------------------------
# 1. A scalar holding a plain value is stored verbatim regardless of the
#    configured serializer, so it reads back cross-serializer with NO
#    fallback. (The storable->json fallback below still applies to aggregate
#    ties and to legacy Storable-frozen scalar segments.)
# -----------------------------------------------------------------------
{
    my $key = 'sf_sv';

    tie my $sv, 'IPC::Shareable', { key => $key, create => 1, destroy => 1, serializer => 'storable' };
    $sv = 'hello';

    my @warns = capture_warns {
        tie my $sv2, 'IPC::Shareable', { key => $key, create => 0, destroy => 1 };
        is $sv2, 'hello', 'scalar: plain value readable cross-serializer (verbatim)';
        my $sv2_knot = tied $sv2;
        is $sv2_knot->attributes('serializer'), 'json',
            'scalar: no fallback needed - serializer stays json';
    };

    ok ! scalar(grep { /Storable-encoded/ } @warns),
        'scalar: no fallback warning for a verbatim plain scalar';
}

# -----------------------------------------------------------------------
# 2. Hash written with storable, re-attached with json default
# -----------------------------------------------------------------------
{
    my $key = 'sf_hv';

    tie my %h, 'IPC::Shareable', { key => $key, create => 1, destroy => 1, serializer => 'storable' };
    %h = (foo => 'bar', n => 42);

    my @warns = capture_warns {
        tie my %h2, 'IPC::Shareable', { key => $key, create => 0, destroy => 1 };
        is $h2{foo}, 'bar', 'hash: string value readable after fallback';
        is $h2{n},   42,    'hash: numeric value readable after fallback';
        my $h2_knot = tied %h2;
        is $h2_knot->attributes('serializer'), 'storable',
            'hash: serializer switched to storable for session';
    };

    ok scalar(grep { /Storable-encoded/ } @warns), 'hash: carp warning emitted';
}

# -----------------------------------------------------------------------
# 3. Warning text mentions the segment hex key
# -----------------------------------------------------------------------
{
    my $key = 'sf_key';

    tie my %h, 'IPC::Shareable', { key => $key, create => 1, destroy => 1, serializer => 'storable' };
    $h{x} = 1;

    my @warns = capture_warns {
        tie my %h2, 'IPC::Shareable', { key => $key, create => 0, destroy => 1 };
    };

    ok scalar(grep { /0x[0-9a-f]+/ } @warns),
        'warning text contains hex segment key';
}

# -----------------------------------------------------------------------
# 4. No warning when serializer is explicitly set to storable
# -----------------------------------------------------------------------
{
    my $key = 'sf_nowarn';

    tie my %h, 'IPC::Shareable', { key => $key, create => 1, destroy => 1, serializer => 'storable' };
    $h{y} = 2;

    my @warns = capture_warns {
        tie my %h2, 'IPC::Shareable', { key => $key, create => 0, destroy => 1, serializer => 'storable' };
        is $h2{y}, 2, 'explicit storable: data still readable';
    };

    ok !scalar(grep { /Storable-encoded/ } @warns),
        'no fallback warning when serializer explicitly set to storable';
}

# -----------------------------------------------------------------------
# 4b. Carp message matches the documented format and serializer attribute
#     is mutated to 'storable' after fallback.
# -----------------------------------------------------------------------
{
    my $key = 'sf_format';

    tie my %h, 'IPC::Shareable', { key => $key, create => 1, destroy => 1, serializer => 'storable' };
    $h{f} = 'g';

    my $knot;
    my @warns = capture_warns {
        $knot = tie my %h2, 'IPC::Shareable', { key => $key, create => 0, destroy => 1 };
    };

    my $msg = join '', @warns;

    like $msg,
        qr/IPC::Shareable: segment 0x[0-9a-f]{8} contains Storable-encoded data; switching serializer to 'storable' for this session\. Re-create the segment to migrate it to JSON\./,
        'carp message matches the full documented format';

    is $knot->attributes('serializer'), 'storable',
        'attributes(serializer) mutated to storable post-fallback';
}

# -----------------------------------------------------------------------
# 5. No warning when segment was written and read with json
# -----------------------------------------------------------------------
{
    my @warns = capture_warns {
        tie my %h, 'IPC::Shareable', { create => 1, destroy => 1, serializer => 'json' };
        $h{z} = 3;
        is $h{z}, 3, 'json round-trip ok';
    };

    ok !scalar(grep { /Storable-encoded/ } @warns),
        'no fallback warning for a json segment';
}

IPC::Shareable::_end;

assert_clean_process();

done_testing;
