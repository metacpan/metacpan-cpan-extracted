use strict;
use warnings FATAL => 'all';
use utf8;

use POSIX qw/uname/;

use lib '.';
use t::Util;
use Mac::OSVersion::Lite;

plan skip_all => 'Test irrelevant on non MacOS' if (uname)[0] !~ /\ADarwin/i;

sub create_instance { bless {} => 'Mac::OSVersion::Lite' }

subtest basic => sub {
    my $version = create_instance;
    lives_ok { $version->_init_by_current_version };
};

done_testing;
