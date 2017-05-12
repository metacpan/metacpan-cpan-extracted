use strict;
use inc::Module::Install;

name('HTML-RobotsMETA');
perl_version '5.006';
all_from('lib/HTML/RobotsMETA.pm');
requires('HTML::Parser', 3);

WriteAll;

1;