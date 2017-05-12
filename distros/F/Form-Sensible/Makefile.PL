use inc::Module::Install;
  
# Define metadata
name            'Form-Sensible';
all_from        'lib/Form/Sensible.pm';

# Specific dependencies
requires        'Moose';
requires        'namespace::autoclean';
requires        'Class::MOP';
requires        'DateTime';
requires        'DateTime::Set';
requires        'DateTime::Format::Natural';
requires        'Data::Dumper';
requires        'Carp';
requires        'Template';
requires        'File::ShareDir';
requires        'FindBin';
test_requires   'Test::More'  => '0.42';
#test_requires   'HTML::Tree'  => '3.23';
install_share   'share';
no_index        'directory'   => 'examples';
# Perhaps we will use this to create command-line based form generators... another day.
#install_script  'myscript';

tests_recursive();

WriteAll;
