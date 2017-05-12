#!/usr/bin/perl -w

use strict;

use Getopt::Long;
use HTML::Hard::Disk;

my $only_newer;

my $result = GetOptions("f" => \$only_newer);

my $src_dir = shift;
my $dest_dir = shift || "./dest";

my $converter =
    HTML::Hard::Disk->new(
        'base_dir' => $src_dir,
        'dest_dir' => $dest_dir
    );

$converter->process_dir_tree('only-newer' => $only_newer);

