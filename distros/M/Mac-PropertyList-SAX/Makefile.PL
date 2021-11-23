# Load the Module::Install bundled in ./inc/
use lib ".";
use inc::Module::Install;

# Define metadata
name            'Mac-PropertyList-SAX';
all_from        'lib/Mac/PropertyList/SAX.pm';

# Specific dependencies
requires        'constant'                  => 1.06;
requires        'enum'                      => 0;
requires        'Encode'                    => 0;
requires        'HTML::Entities'            => 0;
requires        'HTML::Entities::Numbered'  => 0.04;
requires        'Mac::PropertyList'         => 1.501;
requires        'MIME::Base64'              => 0;
requires        'Object::MultiType'         => 0.02;
requires        'XML::SAX::Base'            => 0;
requires        'XML::SAX::Expat'           => 0.40;
requires        'XML::SAX::ParserFactory'   => 0;
build_requires  'Test::More'                => 0.42;
build_requires  'LWP'                       => 0;

auto_install;
WriteAll;

