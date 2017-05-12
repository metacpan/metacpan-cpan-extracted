use strict;
use warnings;
use inc::Module::Install;

# META
name     'Golger';
author   'Fabien Wernli <wernli at in2p3.fr>';
license  'perl';
all_from 'lib/Golger.pm';
abstract_from 'script/loggmann';
readme_pod_from 'script/loggmann';

# REQUIRES
build_requires 'Pod::Markdown' => 0;
requires 'AnyEvent::WebSocket::Client' => 0;
requires 'Getopt::Long::Descriptive' => 0;
requires 'JSON::Any' => 0;
requires 'URI::Escape' => 0;
requires 'version' => 0;

recommends 'Config::Any' => 0;

# CLI
install_script $_ for qw/loggmann/;

WriteAll;
