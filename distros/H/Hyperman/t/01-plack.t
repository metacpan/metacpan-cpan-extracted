use Test::More;
BEGIN {
    plan skip_all => 'Plack required for server conformance tests'
        unless eval { require Plack::Test::Suite; 1 };
}
Plack::Test::Suite->run_server_tests('Hyperman');

# ---- the handler must not drift behind run() --------------------------------
# Every option run() accepts should be reachable from plackup, because plackup
# is how most people start the server. This is the check that was missing when
# the message bus knobs were added to run() and not to the handler: nothing
# noticed, because nothing compared the two lists.
{
    my $xs = do {
        local $/;
        open my $fh, '<', 'xs/hyperman.xs' or last;
        <$fh>;
    };
    my $hd = do {
        local $/;
        open my $fh, '<', 'lib/Plack/Handler/Hyperman.pm' or last;
        <$fh>;
    };

    SKIP: {
        skip 'sources not readable from here', 1 unless $xs && $hd;

        my %accepts = map { $_ => 1 } $xs =~ /strEQ\(key,\s*"([a-z0-9_]+)"\)/g;

        # Handled by name rather than passed straight through: the listener
        # spec, the app itself, `workers` (which also honours plackup's
        # --max-workers), and `deny`, which plackup hands over as a scalar
        # and the handler normalises to an arrayref.
        delete @accepts{ qw(app host port listen deny workers) };

        # Only the PASSTHROUGH list counts. Searching the whole file lets
        # the POD satisfy the check - an option can be documented and still
        # never reach run(), which is exactly the state this test was written
        # to catch.
        my ($passthrough) = $hd =~ /map \{ defined .*?\bqw\((.*?)\)/s;
        $passthrough ||= '';
        my %passed = map { $_ => 1 } split ' ', $passthrough;

        my @missing = sort grep { !$passed{$_} } sort keys %accepts;

        is_deeply(\@missing, [],
            'every run() option is reachable through the Plack handler')
            or diag 'not passed through: ' . join(', ', @missing);
    }
}

done_testing;
