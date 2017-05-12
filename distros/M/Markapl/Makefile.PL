use strict;
use warnings;
use inc::Module::Install;

name 'Markapl';
all_from 'lib/Markapl.pm';

build_requires
    'HTML::Lint'        => 0,
    'Test::HTML::Lint'  => '2.06',
    'Test::More'        => '0.42';

# The list of evil modules
requires
    'B::Hooks::EndOfScope' => 0.05,
    'Devel::Declare' => 0;

# Safer ones
requires
    'String::BufferStack' => 1.15,
    'HTML::Entities' => 0,
    'Exporter::Lite' => 0,
    'Sub::Install' => 0;

author_tests 'xt';

WriteAll;

