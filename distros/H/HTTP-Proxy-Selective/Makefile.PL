#!/usr/bin/env perl
use strict;
use warnings;
use inc::Module::Install 0.91;

all_from 'lib/HTTP/Proxy/Selective.pm';

license 'mit';

requires 'HTTP::Proxy' => 0.22;
requires 'File::Slurp';
requires 'File::Temp';
requires 'IO::Socket::SSL';
requires 'Net::SSLeay';
requires 'Path::Class';
requires 'Config::Tiny';
requires 'HTTP::Headers' => '1.64'; # ->if_modified_since method.
build_requires 'Test::MockObject';

auto_install();

install_script 'script/selective_proxy';
#build_exe('selective_proxy');

# I don't actually use the remote PAR support,
# but adding par_base magically turns on *all* PAR
# support, and so make par works.
#par_base        'BOBTFISH';

WriteAll();
