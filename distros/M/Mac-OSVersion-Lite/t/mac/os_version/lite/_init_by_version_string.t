use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Mac::OSVersion::Lite;

sub create_instance { bless {} => 'Mac::OSVersion::Lite' }

sub cmp_version {
    my ($version, $major, $minor) = @_;
    is $version->major, $major;
    is $version->minor, $minor;
}

subtest name => sub {
    my $version = create_instance;

    $version->_init_by_version_string('tiger');
    cmp_version $version, 10, 4;

    $version->_init_by_version_string('leopard');
    cmp_version $version, 10, 5;

    $version->_init_by_version_string('snow_leopard');
    cmp_version $version, 10, 6;

    $version->_init_by_version_string('lion');
    cmp_version $version, 10, 7;

    $version->_init_by_version_string('mountain_lion');
    cmp_version $version, 10, 8;

    $version->_init_by_version_string('mavericks');
    cmp_version $version, 10, 9;

    $version->_init_by_version_string('yosemite');
    cmp_version $version, 10, 10;

    $version->_init_by_version_string('el_capitan');
    cmp_version $version, 10, 11;

    $version->_init_by_version_string('sierra');
    cmp_version $version, 10, 12;

    $version->_init_by_version_string('high_sierra');
    cmp_version $version, 10, 13;
};

subtest code => sub {
    my $version = create_instance;

    $version->_init_by_version_string('10');
    cmp_version $version, 10, 0;

    $version->_init_by_version_string('10.11');
    cmp_version $version, 10, 11;

    $version->_init_by_version_string('10.9.3');
    cmp_version $version, 10, 9;
};

subtest invalid => sub {
    my $version = create_instance;

    throws_ok(sub {
        $version->_init_by_version_string('__invalid_format__');
    }, qr/\AInvalid format: __invalid_format__\n\z/);
};

done_testing;
