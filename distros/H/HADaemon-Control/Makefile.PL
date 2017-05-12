use inc::Module::Install;
  
# Define metadata
name           'HADaemon-Control';
all_from       'lib/HADaemon/Control.pm';
license        'perl';

# Specific dependencies
requires       'Cwd'                                => '0';
requires       'POSIX'                              => '0';
requires       'File::Path'                         => '2.08';
requires       'Scalar::Util'                       => '0';
requires       'IPC::ConcurrencyLimit::WithStandby' => '0';

#test_requires  'Test::More'     => '0.88';

WriteAll;
