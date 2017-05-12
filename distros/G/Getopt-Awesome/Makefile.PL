use inc::Module::Install;

# Define metadata
name        'Getopt-Awesome';
all_from    'lib/Getopt/Awesome.pm';

# Specific dependencies
requires    'Getopt::Long'  => '2.34';
requires    'Text::Wrap'    => '2001.09292';

no_index directory => 'examples';

repository 'http://github.com/pfischer/Getopt-Awesome';

WriteAll;
