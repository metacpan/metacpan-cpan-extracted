use inc::Module::Install;

name     'JS-YUI-Loader';
all_from 'lib/JS/YUI/Loader.pm';
author   'Robert Krimen <rkrimen@cpan.org>';

build_requires 'Test::More';
build_requires 'Directory::Scratch';

for (split m/\n/, <<_END_) {
Algorithm::Dependency
Carp::Clan::Share
File::Copy
HTML::Declare
JSON 2.08
LWP::UserAgent
Moose
Path::Abstract
Path::Class
Scalar::Util
URI
_END_
    my ($module, $version) = split m/\s+/, $_;
    requires $module, $version;
}

auto_install;

WriteAll;
