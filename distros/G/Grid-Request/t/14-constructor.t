#!/usr/bin/perl


# Test script to check that the constructor honors advertised parameters.

# $Id: 13-constructor.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Basename;
use Log::Log4perl;
use Test::More;
use Grid::Request;
use Grid::Request::Test;


# Get the configured temporary directory
my $req = Grid::Request::Test->get_test_request();
my $tempdir = $req->_config()->val($Grid::Request::HTC::config_section, "tempdir");

if (! defined $tempdir || ! -d $tempdir) {
    plan skip_all => 'tempdir not configured or not a directory.';
} else {
    plan tests => 13;
}

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $name = basename($0);
my $output = "$tempdir/${name}.out";
my $opsys = "Linux";

$req = Grid::Request->new( project    => $project,
                           class      => "myclass",
                           command    => "/bin/echo",
                           error      => "/dev/null",
                           getenv     => 1,
                           initialdir => $tempdir,
                           name       => "myname",
                           opsys      => $opsys,
                           output     => $output,
                           priority   => -1,
                           runtime    => 60,
                           hosts      => "machine",
                           evictable  => "N",
                        );
                                  
is($req->command_count(), 1, "Number of command objects is correct.");
is($req->command(), "/bin/echo", "command() got the correct value.");
is($req->getenv(), 1, "getenv() got the correct value.");
is($req->project(), $project, "project() got the correct value.");
is($req->class(), "myclass", "class() got the correct value.");
is($req->error(), "/dev/null", "error() got the correct value.");
is($req->initialdir(), $tempdir, "initialdir() got the correct value.");
is($req->name(), "myname", "name() got the correct value.");
is($req->output(), $output, "output() got the correct value.");
is($req->opsys(), $opsys, "opsys() got the correct value.");
is($req->priority(), -1, "priority() got the correct value.");
is($req->runtime(), "60", "runtime() got the correct value.");
is($req->hosts(), "machine", "hosts() got the correct value.");
