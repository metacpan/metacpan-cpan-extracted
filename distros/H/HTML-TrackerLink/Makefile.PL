use strict;
use inc::Module::Install;

name           'HTML-TrackerLink';
all_from       'lib/HTML/TrackerLink.pm';
build_requires 'File::Spec'      => '0.80';
build_requires 'Test::More'      => '0.47';

WriteAll;
