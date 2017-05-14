package Mesos::Test::Executor;
use Moo;
use strict;
use warnings;

extends 'Mesos::Executor';
with 'Mesos::Test::Role::Process';


1;
