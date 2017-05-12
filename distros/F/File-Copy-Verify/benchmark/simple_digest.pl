use strict;
use warnings;

use Benchmark qw(cmpthese);
use Path::Tiny;
use feature qw(say);

my $test_set = prepare_test_set([
    [10_000, 1_000],
    [5_000, 10_000],
    [2_000, 100_000],
    [500, 1_000_000],
    [50, 10_000_000],
    [10, 100_000_000],
    [5, 1_000_000_000],
]);

foreach my $test (@$test_set) {
    my ($file, $iter, $size) = @$test;
    say "# $iter iterations on ${size}B file";
    cmpthese(
        $iter,
        {
            'md5'    => sub { $file->digest('MD5') },
            'sha1'   => sub { $file->digest('SHA-1') },
            'sha256' => sub { $file->digest('SHA-256') },
        }
    );
}

sub prepare_test_set {
    my ($test_conf) = @_;


    my @set;
    foreach my $conf (@$test_conf) {
        my ($iter, $size) = @$conf;

        my $temp = Path::Tiny->tempfile();
        $temp->spew('0'x$size);
        push @set, [$temp, $iter, $size];
    }

    return \@set;
}
