# Note: this file was auto-generated by Module::Build::Compat version 0.4220
require 5.009004;
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'Lock::Server',
  'VERSION_FROM' => 'lib/Lock/Server.pm',
  'PREREQ_PM' => {
                   'Daemon::Daemonize' => 0,
                   'Module::Build' => 0,
                   'Test::More' => 0
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [
                   'bin/lock_server'
                 ],
  'PL_FILES' => {}
)
;
