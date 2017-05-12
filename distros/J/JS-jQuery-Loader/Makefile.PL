use inc::Module::Install;

name 'JS-jQuery-Loader';
all_from 'lib/JS/jQuery/Loader.pm';

build_requires 'Test::More';
build_requires 'Directory::Scratch';

for (split m/\n/, <<_END_) {
Carp::Clan::Share
File::Copy
HTML::Declare
LWP::UserAgent
Moose
Path::Abstract
Path::Class
URI
_END_
    my ($module, $version) = split m/\s+/, $_;
    requires $module, $version;
}

auto_install;

WriteAll;

