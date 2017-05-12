use strict;
use inc::Module::Install;

name('EV-Watcher-Bind');
all_from('lib/EV/Watcher/Bind.pm');
requires('EV');

auto_install;
WriteAll;