# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Mac-PropertyList-XS';
all_from        'lib/Mac/PropertyList/XS.pm';

# Specific dependencies
requires        'constant'                  => 1.06;
requires        'enum'                      => 0;
requires        'Encode'                    => 0;
requires        'HTML::Entities'            => 0;
requires        'HTML::Entities::Numbered'  => 0.04;
requires        'Mac::PropertyList'         => 1.601;
requires        'Mac::PropertyList::SAX'    => 1.002;
requires        'Object::MultiType'         => 0.02;
requires        'XML::Parser'               => 0;
build_requires  'Digest::MD5'               => 2.00;
build_requires  'Test::More'                => 0.42;
build_requires  'LWP'                       => 0;

auto_install;
WriteAll;

