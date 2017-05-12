use 5.008001;
use strict;
use warnings;


use inc::Module::Install 0.91;
use ExtUtils::Depends;

name 'Magical-Hooker-Decorate';
all_from 'lib/Magical/Hooker/Decorate.pm';

requires 'parent';
configure_requires 'ExtUtils::Depends' => 0.302; #minimum version that works on Win32+gcc
test_requires 'Test::More';
test_requires 'Test::use::ok';

my $pkg = ExtUtils::Depends->new('Magical::Hooker::Decorate');
$pkg->install('magical_hooker_decorate.h');
$pkg->add_xs('Decorate.xs');
$pkg->add_pm('lib/Magical/Hooker/Decorate.pm' => '$(INST_LIB)/Magical/Hooker/Decorate.pm');

mkdir 'build';
$pkg->save_config('build/IFiles.pm');

makemaker_args(
    $pkg->get_makefile_vars,
    DL_FUNCS => { 'Magical::Hooker::Decorate' => [] },
);

repository 'git://github.com/nothingmuch/magical-hooker-decorate.git';

ppport;

WriteAll;

