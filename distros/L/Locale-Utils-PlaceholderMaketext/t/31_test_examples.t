#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use charnames qw(:full);
use Cwd qw(getcwd chdir);

$ENV{AUTHOR_TESTING}
    or plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';

plan tests => 4;

my @data = (
    {
        test   => '01_maketext_to_gettext',
        path   => 'example',
        script => '-I../lib -T 01_maketext_to_gettext.pl',
        result => <<'EOT',
foo %% %1 bar
foo %1 bar
~ % foo [%1] bar
foo %1 bar %quant(%2,singluar,plural,zero) baz
bar %*(%2,singluar,plural) baz
EOT
    },
    {
        test   => '02_gettext_to_maketext',
        path   => 'example',
        script => '-I../lib -T 02_gettext_to_maketext.pl',
        result => <<'EOT',
foo [_1] bar
foo [_1] bar
~~ % foo ~[[_1]~] bar
foo [_1] bar [quant,_2,singluar,plural,zero] baz
bar [*,_2,singluar,plural] baz
EOT
    },
    {
        test   => '11_expand_maketext',
        path   => 'example',
        script => '-I../lib -T 11_expand_maketext.pl',
        result => <<"EOT",
foo  bar
bar zero baz
~ foo [[_1]] bar [quant,_2,singular,plural,zero] baz
~ foo [0] bar zero baz
~ foo [1] bar 1 singular baz
~ foo [2] bar 2 plural baz
~ foo [3234567.890] bar 3234567.890 plural baz
~ foo [4234567.89] bar 4234567.89 plural baz
foo [_1] bar [*,_2,singular,plural,zero] baz
foo 0 bar zero baz
foo 1 bar 1 singular baz
foo 2 bar 2 plural baz
foo 3.234.567,890 bar 3.234.567,890 plural baz
foo 4.234.567,89 bar 4.234.567,89 plural baz
unicode space 1\N{NO-BREAK SPACE}singular
unicode space 2\N{NO-BREAK SPACE}plural
default space 1 singular
default space 2 plural
EOT
    },
    {
        test   => '12_expand_gettext',
        path   => 'example',
        script => '-I../lib -T 12_expand_gettext.pl',
        result => <<"EOT",
% foo  bar
bar zero baz
foo and bar %quant(%2,singular,plural,zero) baz
foo and bar zero baz
foo and bar 1 singular baz
foo and bar 2 plural baz
foo and bar 3234567.890 plural baz
foo and bar %*(%2,singular,plural,zero) baz
foo and bar zero baz
foo and bar 1 singular baz
foo and bar 2 plural baz
foo and bar 3234567.890 plural baz
EOT
    },
);

for my $data (@data) {
    my $dir = getcwd;
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&3};
    chdir($dir);
    eq_or_diff
        $result,
        $data->{result},
        $data->{test};
}
