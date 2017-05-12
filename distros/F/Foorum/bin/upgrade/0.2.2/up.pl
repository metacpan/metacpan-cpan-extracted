#!/usr/bin/perl

use strict;
use warnings;

# from Foorum v0.2.2 on,
# we require Catalyst::Plugin::PageCache 0.19

use CPAN;
CPAN::Shell->install('Catalyst::Plugin::PageCache');
CPAN::Shell->install('TheSchwartz::Moosified');

1;
