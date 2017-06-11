# Load the Module::Install bundled in ./inc/
use lib ".";
use strict;
use warnings;
use inc::Module::Install 1.05;

my $from = 'lib/Mail/Builder.pm';

# Define metadata
name            'Mail-Builder';
all_from        $from;
readme_from     $from;

perl_version    '5.008';

# Specific dependencies
requires        'MIME::Tools'           => '5.4';
requires        'MIME::Types'           => 0;
requires        'Email::Valid'          => 0;
requires        'Email::Address'        => 0;
requires        'Email::MessageID'      => '1.400';
requires        'Email::Date::Format'   => 0;

requires        'Moose'                 => '0.94';
requires        'namespace::autoclean'  => 0;

requires        'Path::Class'           => 0;
requires        'HTML::TreeBuilder'     => '3.00';
requires        'Text::Table'           => 0;
requires        'Encode'                => 0;

build_requires  'Test::Most'            => 0;
build_requires  'Test::NoWarnings'      => 0;

author_requires 'Test::Pod'             => '1.14';
author_requires 'Test::Pod::Coverage'   => '1.04';
author_requires 'Test::Perl::Critic'    => 0;
author_requires 'Module::Install::ReadmeFromPod'        => 0;


repository 'git://github.com/maros/Mail-Builder.git';

WriteAll;