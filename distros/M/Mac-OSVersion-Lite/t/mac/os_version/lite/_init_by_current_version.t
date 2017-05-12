use strict;
use warnings FATAL => 'all';
use utf8;

use Test::Mock::Cmd qx => \&mock_sw_vers;

use lib '.';
use t::Util;
use Mac::OSVersion::Lite;

sub create_instance { bless {} => 'Mac::OSVersion::Lite' }

sub mock_sw_vers { '12.34' }

subtest succeeded => sub {
    my $version = create_instance;
    $version->_init_by_current_version;

    is $version->major, 12;
    is $version->minor, 34;
};

subtest failed => sub {
    my $version = create_instance;

    throws_ok(sub {
        local $? = -1;
        $version->_init_by_current_version;
    }, qr/\ACommand \`\/usr\/bin\/sw_vers -productVersion\` failed: 12.34 \(exit code: -1\)\n\z/);
};

done_testing;
