use strict;
use warnings;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            'Mediawiki-Blame';
all_from        'lib/Mediawiki/Blame.pm';

license         'perl';

# Specific dependencies

# core
requires        'Carp'                      => 0;

# CPAN
requires        'Algorithm::Annotate'       => 0;
requires        'Class::Spiffy'             => 0;
requires        'DateTime'                  => 0;
requires        'DateTime::Format::ISO8601' => 0;
requires        'LWP::UserAgent'            => 0;
requires        'Params::Validate'          => 0;
requires        'Regexp::Common'            => 0;
requires        'Readonly'                  => 0;
requires        'XML::Twig'                 => 0;

feature
    "Install this if you are interacting with someone's Mediawiki\n"
   ."installation on behalf of a third party, not just yourself.",
    -default              => 0,
    'LWPx::ParanoidAgent' => 0;

build_requires  'Test::More'                => '0.42';
build_requires  'Test::Exception'           => 0;
build_requires  'File::Spec::Functions'     => 0;
build_requires  'Test::Without::Module'     => 0;

auto_install;
WriteAll;
