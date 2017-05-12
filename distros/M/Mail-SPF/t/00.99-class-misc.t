use strict;
use warnings;
use blib;

use Test::More tests => 17;

#### Class Compilation ####

BEGIN {
    use_ok('Mail::SPF::Term');
    use_ok('Mail::SPF::Mech');
    use_ok('Mail::SPF::Mech::All');
    use_ok('Mail::SPF::Mech::IP4');
    use_ok('Mail::SPF::Mech::IP6');
    use_ok('Mail::SPF::Mech::A');
    use_ok('Mail::SPF::Mech::MX');
    use_ok('Mail::SPF::Mech::PTR');
    use_ok('Mail::SPF::Mech::Exists');
    use_ok('Mail::SPF::Mech::Include');
    use_ok('Mail::SPF::Mod');
    use_ok('Mail::SPF::Mod::Exp');
    use_ok('Mail::SPF::Mod::Redirect');
    use_ok('Mail::SPF::Record');
    use_ok('Mail::SPF::v1::Record');
    use_ok('Mail::SPF::v2::Record');
    use_ok('Mail::SPF');
}
