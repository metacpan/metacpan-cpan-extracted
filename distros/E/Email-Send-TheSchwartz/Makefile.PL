# $Id$

use inc::Module::Install;

name            'Email-Send-TheSchwartz';
all_from        'lib/Email/Send/TheSchwartz.pm';

requires        'Email::Address';
requires        'Return::Value';
requires        'TheSchwartz';
recommends      'TheSchwartz::Worker::SendEmail';
build_requires  'Test::More';

auto_include;
auto_install;
WriteAll;
