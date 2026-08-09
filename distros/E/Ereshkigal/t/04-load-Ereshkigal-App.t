#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

my @modules = (
    'Ereshkigal::App',
    'Ereshkigal::App::Command::add',
    'Ereshkigal::App::Command::ban',
    'Ereshkigal::App::Command::banned',
    'Ereshkigal::App::Command::checkpoint',
    'Ereshkigal::App::Command::remove',
    'Ereshkigal::App::Command::start',
    'Ereshkigal::App::Command::status',
    'Ereshkigal::App::Command::stop',
    'Ereshkigal::App::Command::unban',
);

plan tests => scalar(@modules);

foreach my $module (@modules) {
    use_ok($module) || print "Bail out!\n";
}

diag( "Testing Ereshkigal::App $Ereshkigal::App::VERSION, Perl $], $^X" );
