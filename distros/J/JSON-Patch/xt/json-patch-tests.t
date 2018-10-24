#!perl

use strict;
use warnings FATAL => 'all';

use File::Spec::Functions qw(catfile);
use HTTP::Tiny;
use JSON;
use JSON::Patch qw(diff patch);
use Test::More;

sub run_diff_tests {
    my $json = shift;
    my $t = JSON->new->decode($json);

    return if ($t->{error});
    return unless ($t->{doc} and $t->{expected} and $t->{patch});

    return if (
        ref $t->{patch} eq 'ARRAY' and
        @{$t->{patch}} and
        $t->{patch}->[0]->{op} eq 'test'
    );

    my $patch = diff($t->{doc}, $t->{expected});

    # roundtrip
    eval { patch($t->{doc}, $patch) };
    if ($@) {
        fail($t->{comment});
        diag "DIFF:\n$json";
        return;
    }

    is_deeply($t->{doc}, $t->{expected}, $t->{comment}) ||
        diag "DIFF:\n$json";
}

sub run_patch_tests {
    my $json = shift;
    my $t = JSON->new->decode($json);;

    eval { JSON::Patch::patch($t->{doc}, $t->{patch}) };
    if ($@) {
        if (exists $t->{error}) {
            ok(1);
        } else {
            diag "PATCH:\n$json";
            fail("Unexpected exception: $@");
        }

        return;
    } else {
        if (exists $t->{error}) {
            diag "PATCH:\n$json";
            fail("Should be error: $t->{error}");
            return;
        }
    }

    unless (exists $t->{expected}) {
        pass($t->{comment});
        return;
    }

    is_deeply($t->{doc}, $t->{expected}, $t->{comment}) ||
        diag "PATCH:\n$json";
}


my %FILES = (
    'spec_tests.json' => 'http://raw.githubusercontent.com/json-patch/json-patch-tests/master/spec_tests.json',
    'tests.json'      => 'http://raw.githubusercontent.com/json-patch/json-patch-tests/master/tests.json',
);

if ($ENV{FETCH_EXTERNAL_TESTS}) {
    for my $file (sort keys %FILES) {
        diag "Fetching $FILES{$file}";

        my $resp = HTTP::Tiny->new->get($FILES{$file});
        die "Unable to fetch test file: $resp->{status} $resp->{reason}"
            unless ($resp->{success});

        open(my $fh, '>', catfile("xt", $file)) or
            die "Failed to open file '$file' ($!)";
        print $fh $resp->{content};
        close($fh);
    }
}

my @test_files = grep { -e } map { catfile("xt", $_) } sort keys %FILES;

unless (@test_files) {
    plan skip_all => 'Tests files unavailable';
    exit 0;
}

for my $file (@test_files) {
    open(my $fh, '<', $file) or die "Failed to open file '$file' ($!)";
    my $tests = do { local $/; <$fh> }; # load whole file
    close($fh);

    $tests = JSON->new->relaxed->decode($tests);
    my $count = 0;

    for (@{$tests}) {
        $count++;

        diag "$file $count/" . scalar @{$tests} if ($ENV{DEBUG});
        next if ($_->{disabled});

        my $json = JSON->new->encode($_); # isolate tests

        run_diff_tests($json);
        run_patch_tests($json);
    }
}

done_testing();
