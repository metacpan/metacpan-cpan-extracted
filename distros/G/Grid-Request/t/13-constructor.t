#!/usr/bin/perl

# $Id: 13-constructor.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Basename;
use Log::Log4perl;
use Test::More tests => 14;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $name = basename($0);
my $output = "/usr/local/scratch/${name}.out";
my $opsys = "Linux";

my $htc = Grid::Request->new( project    => $project,
                              class      => "myclass",
                              command    => "/bin/echo",
                              error      => "/dev/null",
                              getenv     => 1,
                              initialdir => "/usr/local/scratch",
                              length     => "long",
                              name       => "myname",
                              opsys      => $opsys,
                              output     => $output,
                              priority   => -1,
                              runtime    => 60,
                              hosts      => "machine",
                              evictable  => "N",
                           );
                                  
is($htc->command_count(), 1, "Number of command objects is correct.");
is($htc->command(), "/bin/echo", "command() got the correct value.");
is($htc->getenv(), 1, "getenv() got the correct value.");
is($htc->project(), $project, "project() got the correct value.");
is($htc->class(), "myclass", "class() got the correct value.");
is($htc->error(), "/dev/null", "error() got the correct value.");
is($htc->initialdir(), "/usr/local/scratch", "initialdir() got the correct value.");
is($htc->length(), "long", "long() got the correct value.");
is($htc->name(), "myname", "name() got the correct value.");
is($htc->output(), $output, "output() got the correct value.");
is($htc->opsys(), $opsys, "opsys() got the correct value.");
is($htc->priority(), -1, "priority() got the correct value.");
is($htc->runtime(), "60", "runtime() got the correct value.");
is($htc->hosts(), "machine", "hosts() got the correct value.");
