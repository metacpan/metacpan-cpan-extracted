#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Gearman::Spawner;
use Getopt::Long;

GetOptions(
    'class=s'       => \(my $class),
    'data=s'        => \(my $data = ''),
    'M|preload=s@'  => \(my $preload),
    'server=s@'     => \(my $servers),
    'n|count=i'     => \(my $count = 1),
    'verbose!'      => \(my $verbose),
);

$class ||= shift;
die "need --class" unless $class;

my $spawner = Gearman::Spawner->new(
    servers => $servers,
    preload => $preload || [],
    workers => {
        $class => {
            count   => $count,
            data    => $data,
        },
    },
);
my $pid = $spawner->pid;
$verbose && warn "Running spawner in process $pid";

select undef, undef, undef, undef;
