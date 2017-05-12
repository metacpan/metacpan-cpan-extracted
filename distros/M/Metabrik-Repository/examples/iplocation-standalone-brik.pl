#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Metabrik::Core::Context;
use Metabrik::Lookup::Iplocation;

my $context = Metabrik::Core::Context->new;
$context->brik_init or die("[FATAL] context init failed\n");

my $li = Metabrik::Lookup::Iplocation->new_from_brik_init($context)
   or exit(1);

$li->update
   or exit(2);

my $info = $li->from_ip("104.47.125.219")
   or exit(3);

print Dumper($info);
