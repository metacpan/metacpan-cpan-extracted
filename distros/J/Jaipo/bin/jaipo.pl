#!/usr/bin/perl
use warnings;
use strict;
use utf8;

use Jaipo;
my $jaipo = Jaipo->new(
    "ui"      => "console",
    "service" => "all",
    "notify"  => 1,
);
$jaipo->init;
$jaipo->run;

# or..
__END__
