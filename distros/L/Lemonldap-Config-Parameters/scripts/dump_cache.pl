#!/usr/bin/perl -w
use strict;
use Lemonldap::Config::Parameters;
my $key=shift||'/tmp/CONF';
Lemonldap::Config::Parameters::f_dump($key);

