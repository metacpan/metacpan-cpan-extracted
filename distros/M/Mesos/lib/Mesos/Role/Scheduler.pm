package Mesos::Role::Scheduler;
use Moo::Role;
use strict;
use warnings;
use Mesos::Messages;

requires qw(
    registered
    reregistered
    disconnected
    resourceOffers
    offerRescinded
    statusUpdate
    frameworkMessage
    slaveLost
    executorLost
    error
);


1;
