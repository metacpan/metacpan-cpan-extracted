use strict;
use warnings;
use Test::More;

use Gtk2;

BEGIN {
    unless (Gtk2->init_check) {
        plan skip_all => 'unable to initialize Gtk2';
    }

    plan tests => 4;

    use_ok('Log::Dispatch::Gtk2::Notify');
}

my $notify = Log::Dispatch::Gtk2::Notify->new(
    name  => 'notify', min_level => 'debug',
    title => 'Log::Dispatch::Gtk2::Notify tests',
);

isa_ok($notify, 'Log::Dispatch::Gtk2::Notify');
isa_ok($notify, 'Log::Dispatch::Output');

eval {
    $notify->log(level => 'info', message => 'success');
};
ok(!$@, 'test message');
