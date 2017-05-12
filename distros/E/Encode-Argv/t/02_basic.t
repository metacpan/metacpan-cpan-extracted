use strict;
use utf8;
use Test::More (tests => 3);

BEGIN
{
    use_ok("Encode::Argv");
}

my @args = qw(日本語 すもも コーヒー abcdef);
{
    local @ARGV = map { Encode::encode('cp932', $_) } @args;
    Encode::Argv->import('cp932');

    is_deeply(\@ARGV, \@args);
}

{
    local @ARGV = map { Encode::encode('cp932', $_) } @args;
    Encode::Argv->import('cp932', 'euc-jp');

    is_deeply(\@ARGV, [ map { Encode::encode('euc-jp', $_) } @args ]);
}