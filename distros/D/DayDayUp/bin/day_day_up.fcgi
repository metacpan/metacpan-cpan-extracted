#!/usr/bin/perl

# Copyright (C) 2008, Sebastian Riedel.

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use Mojo::Server::FCGI::Prefork;

my $fcgi = Mojo::Server::FCGI::Prefork->new( app_class => 'DayDayUp' );
$fcgi->min_spare_servers(1);
$fcgi->max_spare_servers(3);
$fcgi->daemonize;
$fcgi->run('/tmp/daydayup_fcgi.socket');

1;