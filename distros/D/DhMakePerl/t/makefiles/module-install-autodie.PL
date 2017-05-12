#!/usr/bin/perl -w
use strict;
use inc::Module::Install;

# This isn't the same as the real autodie makefile, which takes pains
# to be friendlier to older versions of dh-make-perl.  However it is
# indicative of what can be found a typical Module::Install file.

name		'autodie';

all_from	'lib/autodie.pm';

version         1.994;
test_requires	'Test::More';
author         'Paul Fenwick <pjf@cpan.org>';

requires	'perl' => '5.8.0';

recommends	'IPC::System::Simple' => '0.12'; # For autodying system()

resources      repository => 'http://github.com/pfenwick/autodie/tree/master';
resources      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=autodie';
resources      license    => 'http://dev.perl.org/licenses/';
resources	Blog       => 'http://pjf.id.au/blog/toc.html?tag=autodie';

installdirs    'perl';    # This overwrites a core module!

WriteAll;
