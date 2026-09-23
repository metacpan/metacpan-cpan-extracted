use strict;
use warnings;
use Test::More;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

# Every shipped module must carry the dist version. A module left behind is
# not re-indexed by PAUSE for that release, and a generated one can revert
# silently: Schema.pm is written by author/gen-schema.pl.
my $main = 'lib/EV/Telegram/TDLib.pm';

sub version_of {
    my ($file) = @_;
    open my $h, '<', $file or die "$file: $!";
    while (<$h>) { return $1 if /our \$VERSION\s*=\s*'([^']+)'/ }
    return undef;
}

my $want = version_of($main);
ok defined $want, "the main module declares a version ($want)";

my @files = ($main, glob 'lib/EV/Telegram/TDLib/*.pm');
# a glob that matches nothing would leave @wrong empty and pass
cmp_ok scalar(@files), '>', 10, 'the scan found modules to check';
my @wrong;
for my $f (@files) {
    my $got = version_of($f);
    push @wrong, "$f has " . (defined $got ? $got : 'no version')
        unless defined $got && $got eq $want;
}

is_deeply \@wrong, [], "every shipped module is at $want";
diag $_ for @wrong;

done_testing;
