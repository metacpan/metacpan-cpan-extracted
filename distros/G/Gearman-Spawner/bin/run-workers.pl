#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Gearman::Spawner;
use Getopt::Long;
use YAML 'LoadFile';

GetOptions(
    'config=s'      => \(my $config_file),
    'verbose!'      => \(my $verbose),
);

$config_file ||= shift;

die "need --config" unless $config_file;

my $config = LoadFile($config_file);

my $spawner = Gearman::Spawner->new(%$config);
my $pid = $spawner->pid;
$verbose && warn "Running spawner in process $pid";

select undef, undef, undef, undef;

# Example config:
__END__

---
servers:
    - localhost:7003
include:
    - t/lib
preload:
    - YAML
workers:
    MethodWorker:
        count: 3
        max_jobs: 100
