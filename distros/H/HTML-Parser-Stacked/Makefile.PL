use strict;
use inc::Module::Install;

name('HTML-Parser-Stacked');
all_from('lib/HTML/Parser/Stacked.pm');
requires('HTML::Parser', 3);

auto_install;
WriteAll;