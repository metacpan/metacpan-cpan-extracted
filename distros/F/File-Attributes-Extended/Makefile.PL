use strict;
use warnings;
use inc::Module::Install;

name('File-Attributes-Extended');
author('Jonathan Rockway <jrockway@cpan.org>');
version_from('lib/File/Attributes/Extended.pm');
abstract_from('lib/File/Attributes/Extended.pm');
license('Perl');
include('ExtUtils::AutoInstall');
requires('File::ExtAttr');
requires('File::Attributes' => 0.04);

build_requires('Directory::Scratch' => 0.05);
build_requires('Test::More');

auto_install();
WriteAll();
