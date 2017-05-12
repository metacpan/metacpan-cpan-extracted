#!/usr/bin/env perl
use strict;
use warnings;
use Gearman::Driver::Console::Client;
my $client = Gearman::Driver::Console::Client->new_with_options;
$client->run;