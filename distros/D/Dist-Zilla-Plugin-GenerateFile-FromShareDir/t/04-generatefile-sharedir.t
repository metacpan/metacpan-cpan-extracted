use strict;
use warnings;

# this is just like t/01-basic.t except we use [GenerateFile::ShareDir].

use Path::Tiny;
my $code = path('t', '01-basic.t')->slurp_utf8;

my $begin_warnings = <<'END';
my @warnings = warnings {
END

my $end_warnings = <<'END';
};  # end warnings capture

cmp_deeply(
    \@warnings,
    superbagof(re(qr/^\Q!!! [GenerateFile::ShareDir] is deprecated and may be removed in a future release; replace it with [GenerateFile::FromShareDir]\E/)),
    'deprecation warning was seen',
);
END

$code =~ s/^use if \$ENV\{AUTHOR_TESTING\}, 'Test::Warnings';$/use Test::Warnings 0.009 ':no_end_test', ':all';/m;
$code =~ s/::GenerateFile::FromShareDir',/::GenerateFile::ShareDir',/g;
$code =~ s/::GenerateFile::FromShareDir /::GenerateFile::ShareDir /g;
$code =~ s/'GenerateFile::FromShareDir'/'GenerateFile::ShareDir'/g;

$code =~ s/^((\s+)dist => '[^']+',)$/$1\n$2version => Dist::Zilla::Plugin::GenerateFile::FromShareDir->VERSION,/m,

$code =~ s/^(my \$tzil = .*\n)/$begin_warnings\n$1/m;
$code =~ s/done_testing;/$end_warnings\nhad_no_warnings if \$ENV\{AUTHOR_TESTING\};\ndone_testing;/;

eval $code;
die $@ if $@;
