# -*- perl -*-

use strict;
use warnings;
use inc::Module::Install;

name           ('Elive');
module_name    ('Elive');
author         ('David Warring <david.warring@gmail.com>');
all_from       ('lib/Elive.pm');
license	       ('perl');
install_script ('elive_query', 'elive_raise_meeting', 'elive_lint_config');

requires(
    'Class::Accessor'              => 0,
    'Class::Data::Inheritable'     => 0,
    'Clone'                        => 0,
    'Date::Parse'                  => 0,
    'Carp'                         => 0,  # for scripts
    'File::Spec'                   => 0,
    'File::Basename'               => 0,
    'Getopt::Long'                 => 2.35,  # for scripts
    'HTML::Entities'               => 0,
    'IO::Interactive'              => 0,
    'MIME::Types'                  => 0,
    'Mouse'                        => 0.81,
    'Mouse::Util::TypeConstraints' => 0,
    'Pod::Usage'                   => 1.33,  # for elive_raise_meeting
    'parent'                       => 0,
    'Scalar::Util'                 => 0,
    'SOAP::Lite'                   => 0.712,
    'Term::ReadKey'                => 0,
    'Term::ReadLine'               => 0,
    'Time::Local'                  => 0,
    'Try::Tiny'                    => 0,
    'URI'                          => 0,
    'URI::Escape'                  => 0,
    'YAML::Syck'                   => 0,
    'XML::Simple'                  => 0,
    );

recommends(
    'Term::ReadLine::Perl'         => 0,  
    );

test_requires (
    'File::Temp'                   => 0,
    'Test::More'                   => 0.98,
    'Test::Warn'                   => 0,
    'Test::Fatal'                  => 0,
    'version'                      => 0,
    );

repository("https://github.com/dwarring/p5-Bb-Collaborate.git");

WriteAll;
