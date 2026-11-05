use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);

# Test 1: Standard load under the current environment
BEGIN {
    use_ok('Meteorology::PET::Thornthwaite') or BAIL_OUT("Cannot load module");
}

# Test 2: Simulate an environment where PDL is completely missing
subtest 'compile and instantiate without PDL' => sub {
    my $code = <<'EOF';
use strict;
use warnings;

# Hook @INC to simulate missing PDL
BEGIN {
    unshift @INC, sub {
        my ($self, $filename) = @_;
        if ($filename =~ /^PDL(?:\.pm|\/)/) {
            die "Simulated missing PDL module\n";
        }
        return undef;
    };
}

use Meteorology::PET::Thornthwaite;

my $calc = eval {
    Meteorology::PET::Thornthwaite->new({
        LATITUDE          => 40.0,
        TEMPERATURE_CLIMO => [ (15.0) x 12 ],
        TEMPERATURE_UNITS => 'C',
        PET_UNITS         => 'mm',
    });
};

die "Instantiation failed: $@" if $@ || !$calc;
exit 0;
EOF

    my $perl = $^X;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $perl, '-Ilib');
    print $in $code;
    close $in;

    my $stdout = do { local $/; <$out> };
    my $stderr = do { local $/; <$err> };
    waitpid($pid, 0);
    my $exit_status = $? >> 8;

    is($exit_status, 0, "Subprocess exited cleanly without PDL")
        or diag("STDERR:\n$stderr\nSTDOUT:\n$stdout");
};

done_testing();
