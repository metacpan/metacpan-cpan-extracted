use strict;
use warnings;

use Test::More;

# this is just like t/09-unicode.t, except the minimum perl prereq is not known
# to be at least 5.008006, so a prereq on JSON::PP is injected to enable the
# target toolchain to be able to deal with non-ascii characters in META.json
# (not soon enough for the distribution being installed, sadly)

use Path::Tiny;
my $code = path('t', '09-unicode.t')->slurp_utf8;

$code =~ s/perl => '5.010'/perl => '0'/g;
$code =~ s/^(\s+configure => \{ requires => \{ perl => '0' \})( \},)$/$1, suggests => { 'JSON::PP' => '2.27300' }$2/m;

my $test = <<'CODE';
cmp_deeply(
    $tzil->log_messages,
    superbagof(
        re(qr/^\[Git::Contributors\] Warning: distribution has non-ascii characters in contributor names. META.json will be unparsable on perls <= 5.8.6 when JSON::PP is lower than 2.27300$/),
    ),
    'got a warning about META.json being unparsable on perls <= 5.8.6 with old JSON::PP',
);
CODE
$code =~ s/^(diag 'got log messages: ')/$test\n$1/m;

eval $code;
die $@ if $@;
