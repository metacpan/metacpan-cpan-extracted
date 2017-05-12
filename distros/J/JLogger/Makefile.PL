use inc::Module::Install;

name 'JLogger';

all_from 'lib/JLogger.pm';

requires 'AnyEvent::XMPP';
requires 'Class::Load';
requires 'YAML';
requires 'DBI';
requires 'DBIx::Connector';

test_requires 'DBD::SQLite';

install_script 'script/jlogger';

resources
  bugtracker => 'https://github.com/und3f/jlogger/issues',
  repository => 'https://github.com/und3f/jlogger';

WriteAll;
