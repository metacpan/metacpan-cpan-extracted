#!perl -T
use strict;
use warnings qw(all);

use Test::More tests => 4;

BEGIN {
    use_ok(q(Test::Builder));
    use_ok(q(Test::Mojibake));
    use_ok(q(Dist::Zilla));
    use_ok(q(Dist::Zilla::Plugin::MojibakeTests));
}

diag(qq(Testing Dist::Zilla::Plugin::MojibakeTests v$Dist::Zilla::Plugin::MojibakeTests::VERSION, Perl $], $^X));
diag(qq(Using Dist::Zilla v$Dist::Zilla::VERSION));
diag(qq(Using Test::Mojibake v$Test::Mojibake::VERSION));
diag(qq(Using Test::Builder v$Test::Builder::VERSION));
