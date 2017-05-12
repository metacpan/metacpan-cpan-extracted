# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name     'IO-Socket-Telnet';
all_from 'lib/IO/Socket/Telnet.pm';
githubmeta;

WriteAll;

