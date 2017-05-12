#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Dist::Zilla::MintingProfile::SYP));
};

diag(qq(Dist::Zilla::MintingProfile::SYP v$Dist::Zilla::MintingProfile::SYP::VERSION, Perl $], $^X));
