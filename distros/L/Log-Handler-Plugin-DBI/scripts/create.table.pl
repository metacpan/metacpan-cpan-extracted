#!/usr/bin/env perl

use strict;
use warnings;

use Config::Plugin::Tiny; # For config_tiny().

use Data::Dumper::Concise; # For Dumper().

use Log::Handler::Plugin::DBI::CreateTable;

# -----------------------------------------

my($config) = config_tiny(undef, File::Spec -> catfile('t', '/config.logger.conf') );

Dumper($config);

Log::Handler::Plugin::DBI::CreateTable -> new({config => $config}) -> create_log_table;
