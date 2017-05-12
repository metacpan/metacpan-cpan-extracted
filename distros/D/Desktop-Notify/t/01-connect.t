#!perl -T

use Test::More;

unless ($ENV{DBUS_SESSION_BUS_ADDRESS})
{
    plan skip_all => 'D-Bus session bus not running';
    exit 0;
}

plan tests => 3;

use_ok('Desktop::Notify');

my $notify;

eval { $notify = new Desktop::Notify };

ok($notify, 'connect with default options');

$notify = undef;
eval { $notify = new Desktop::Notify
           (bus => Net::DBus->session,
            service => 'org.freedesktop.Notifications',
            objpath => '/org/freedesktop/Notifications',
            objiface => 'org.freedesktop.Notifications') };

ok($notify, 'connect with explicit options');
