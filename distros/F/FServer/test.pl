#!/usr/bin/perl -w
use strict;
use FServer;

my $object = FServer::new("Asuka", "bulbhead");
print $object->display();
