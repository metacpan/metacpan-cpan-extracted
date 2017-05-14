package Mesos::Role::Executor;
use Moo::Role;
use strict;
use warnings;

requires qw(
    registered
    reregistered
    disconnected
    launchTask
    killTask
    frameworkMessage
    shutdown
    error
);


1;
