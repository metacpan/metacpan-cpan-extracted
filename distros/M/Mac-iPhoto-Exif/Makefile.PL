# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install 1.05;

my $from = 'lib/Mac/iPhoto/Exif.pm';

# Define metadata
name            'Mac-iPhoto-Exif';
all_from        $from;
readme_from     $from;

perl_version    '5.010';

# Specific dependencies
requires        'version'                   => 0;
requires        'Moose'                     => '0.94';
requires        'MooseX::Getopt'            => '0';
requires        'Scalar::Util'              => '0';
requires        'XML::LibXML'               => '0';
requires        'Term::ANSIColor'           => '0';
requires        'File::Copy'                => '0';
requires        'DateTime'                  => '0';
requires        'Image::ExifTool'           => '0';
requires        'Image::ExifTool::Location' => '0';
requires        'Unicode::Normalize'        => '0';
requires        'Encode'                    => '0';
requires        'Path::Class'               => '0';

build_requires  'Test::Most'                => 0;
build_requires  'Test::NoWarnings'          => 0;

author_requires 'Test::Pod'                 => '1.14';
author_requires 'Test::Pod::Coverage'       => '1.04';
author_requires 'Test::Perl::Critic'        => 0;
author_requires 'Module::Install::ReadmeFromPod'        => 0;

install_script 'bin/iphoto2exif';

repository 'git://github.com/maros/Mac-iPhoto-Exif.git';

WriteAll;