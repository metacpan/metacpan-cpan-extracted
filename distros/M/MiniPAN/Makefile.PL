use inc::Module::Install;

name     'MiniPAN';
all_from 'lib/MiniPAN.pm';
author   'Tobias Kirschstein <lev@cpan.org>';

requires 'Archive::Tar';
requires 'File::Path';
requires 'IO::Uncompress::Gunzip';
requires 'LWP::UserAgent';
requires 'Spiffy';

build_requires 'Test::More';

requires_external_bin 'sudo';
requires_external_bin 'make';
requires_external_bin 'yes';

install_script 'minipan';

auto_install;

WriteAll;

