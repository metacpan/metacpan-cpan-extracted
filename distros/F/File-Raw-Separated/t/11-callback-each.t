use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Basic: callback fires per row, sees an arrayref of fields
{
    my @collected;
    file_csv_parse_buf_each(
        "a,b\nc,d\ne,f\n",
        sub { push @collected, [@{$_[0]}] },   # explicit copy
    );
    is_deeply(
        \@collected,
        [['a','b'], ['c','d'], ['e','f']],
        'each: 3 rows received with correct fields',
    );
}

# AV-reuse aliasing: stashing $_[0] verbatim sees the LATER state
# because the parser av_clear()s the same AV after each call.
{
    my @stashed;
    file_csv_parse_buf_each(
        "a,b\nc,d\n",
        sub { push @stashed, $_[0] },          # NOT a copy
    );
    is(scalar(@stashed), 2, 'callback fired twice');
    # After the parse finishes, both stashed refs point at the same now-
    # empty AV (av_clear ran after each callback). Verify the contract.
    is_deeply($stashed[0], [], 'stashed row 0 is empty (aliased)');
    is_deeply($stashed[1], [], 'stashed row 1 is empty (aliased)');
    ok($stashed[0] == $stashed[1], 'both refs are the SAME AV (aliasing)');
}

# Callback dies => parse aborts and exception propagates
{
    my $rc = eval {
        file_csv_parse_buf_each(
            "a\nb\nc\n",
            sub { die "stop on row 2\n" if $_[0][0] eq 'b' },
        );
        1;
    };
    ok(!$rc, 'parse aborts when callback dies');
    is($@, "stop on row 2\n", 'die message propagated verbatim');
}

# Options pass-through
{
    my @collected;
    file_csv_parse_buf_each(
        "a;b\nc;d\n",
        sub { push @collected, [@{$_[0]}] },
        { sep => ';' },
    );
    is_deeply(
        \@collected,
        [['a','b'], ['c','d']],
        'each: custom separator',
    );
}

# Type-checking arguments
{
    my $rc = eval { file_csv_parse_buf_each("x\n", "not a coderef"); 1 };
    ok(!$rc, 'non-CODE-ref second arg croaks');
    like($@, qr/CODE/, 'error mentions CODE');
}

done_testing;
