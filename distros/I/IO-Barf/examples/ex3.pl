#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark qw(cmpthese);
use IO::All;
use IO::Any;
use IO::Barf;
use File::Slurp qw(write_file);
use File::Temp;
use Path::Tiny;

# Temporary files.
my $temp1 = File::Temp->new->filename;
my $temp2 = File::Temp->new->filename;
my $temp3 = File::Temp->new->filename;
my $temp4 = File::Temp->new->filename;
my $temp5 = File::Temp->new->filename;

# Some data.
my $data = 'x' x 1000;

# Benchmark (10s).
cmpthese(-10, {
        'File::Slurp' => sub {
                write_file($temp3, $data);
                unlink $temp3;
        },
        'IO::All' => sub {
                $data > io($temp4);
                unlink $temp4;
        },
        'IO::Any' => sub {
                IO::Any->spew($temp2, $data);
                unlink $temp2;
        },
        'IO::Barf' => sub {
                barf($temp1, $data);
                unlink $temp1;
        },
        'Path::Tiny' => sub {
                path($temp5)->spew($data);
                unlink $temp5;
        },
});

# Output like this:
#                Rate  Path::Tiny     IO::Any     IO::All File::Slurp    IO::Barf
# Path::Tiny   3210/s          --        -17%        -51%        -85%        -91%
# IO::Any      3859/s         20%          --        -41%        -82%        -89%
# IO::All      6574/s        105%         70%          --        -70%        -81%
# File::Slurp 21615/s        573%        460%        229%          --        -39%
# IO::Barf    35321/s       1000%        815%        437%         63%          --