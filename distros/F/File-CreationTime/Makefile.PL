use strict;
use warnings;
use inc::Module::Install;

name      'File-CreationTime';
all_from  'lib/File/CreationTime.pm';
requires  'File::Attributes';
build_requires 'Test::More';

if($^O =~ /darwin/){
    requires 'MacOSX::File::Info';
}

WriteAll();
