#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark qw(cmpthese);
use IO::All;
use IO::Any;
use IO::Barf;
use File::Raw qw(spew);
use File::Slurp qw(write_file);
use File::Temp;
use Path::Tiny;

# Temporary files.
my $temp1 = File::Temp->new->filename;
my $temp2 = File::Temp->new->filename;
my $temp3 = File::Temp->new->filename;
my $temp4 = File::Temp->new->filename;
my $temp5 = File::Temp->new->filename;
my $temp6 = File::Temp->new->filename;

# Some data.
my $data = 'x' x 1000;

# Benchmark (10s).
cmpthese(-10, {
        'File::Raw' => sub {
                file_spew($temp1, $data);
                unlink $temp1;
        },
        'File::Slurp' => sub {
                write_file($temp2, $data);
                unlink $temp2;
        },
        'IO::All' => sub {
                $data > io($temp3);
                unlink $temp3;
        },
        'IO::Any' => sub {
                IO::Any->spew($temp4, $data);
                unlink $temp4;
        },
        'IO::Barf' => sub {
                barf($temp5, $data);
                unlink $temp5;
        },
        'Path::Tiny' => sub {
                path($temp6)->spew($data);
                unlink $temp6;
        },
});

# Output like this:
# X270, Intel(R) Core(TM) i5-6300U CPU @ 2.40GHz
#                Rate Path::Tiny   IO::All  IO::Any File::Slurp IO::Barf File::Raw
# Path::Tiny   5707/s         --      -27%     -36%        -71%     -75%      -84%
# IO::All      7814/s        37%        --     -12%        -60%     -66%      -79%
# IO::Any      8899/s        56%       14%       --        -54%     -61%      -76%
# File::Slurp 19521/s       242%      150%     119%          --     -14%      -47%
# IO::Barf    22735/s       298%      191%     155%         16%       --      -38%
# File::Raw   36606/s       541%      368%     311%         88%      61%        --