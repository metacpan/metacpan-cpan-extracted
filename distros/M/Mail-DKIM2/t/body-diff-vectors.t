use strict;
use warnings;
use Test::More;
use FindBin;
use JSON::PP;

use Mail::DKIM2::MessageInstance;

# The shared body-diff vectors every implementation checks
# (util/build-body-diff-vectors.pl). Only in the interop repository, not
# in the CPAN distribution.
my $file = "$FindBin::Bin/../../vectors/body-diff.json";
plan skip_all => 'vectors/body-diff.json not present' unless -e $file;

open my $fh, '<', $file or die "$file: $!";
my $cases = decode_json(do { local $/; <$fh> })->{cases};

for my $c (@$cases) {
    my $r = Mail::DKIM2::MessageInstance::_body_diff(
        $c->{cur}, $c->{prev}, $c->{max_literals});
    is_deeply(!defined $r ? 'identical' : $r, $c->{expect}, $c->{name});
}

done_testing;
