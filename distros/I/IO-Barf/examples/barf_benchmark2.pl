#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark qw(cmpthese);
use File::Temp;

# Temporary files.
my $temp1 = File::Temp->new->filename;
my $temp2 = File::Temp->new->filename;
my $temp3 = File::Temp->new->filename;
my $temp4 = File::Temp->new->filename;

# Some data.
my $data = 'x' x 1000;

# Benchmark (10s).
cmpthese(-10, {
        'File::Slurp' => sub {
                require File::Slurp;
                File::Slurp::write_file($temp1, $data);
                unlink $temp1;
        },
        'IO::Any' => sub {
                require IO::Any;
                IO::Any->spew($temp2, $data);
                unlink $temp2;
        },
        'IO::Barf' => sub {
                require IO::Barf;
                IO::Barf::barf($temp3, $data);
                unlink $temp3;
        },
        'Path::Tiny' => sub {
                require Path::Tiny;
                Path::Tiny::path($temp4)->spew($data);
                unlink $temp4;
        },
});

# Output like this:
# T460s, Intel(R) Core(TM) i7-6600U CPU @ 2.60GHz
#                Rate     IO::Any  Path::Tiny File::Slurp    IO::Barf
# IO::Any      8692/s          --        -20%        -65%        -77%
# Path::Tiny  10926/s         26%          --        -56%        -71%
# File::Slurp 24669/s        184%        126%          --        -34%
# IO::Barf    37193/s        328%        240%         51%          --