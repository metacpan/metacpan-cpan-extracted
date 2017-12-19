use strict;
use warnings;

use Test::More;
use Path::Tiny;
my $code = path('t', '02-different-versions.t')->slurp_utf8;

$code =~ s/delete \$ENV\{V\};//;

$ENV{V} = '1.23';
eval $code;

like(
    $@,
    qr/you cannot change the distribution version with \$V \Qalong with bump_only_matching_versions: update the .pm file(s) first\E/,
    'dzil configuration fails when $V is set',
);

done_testing;
