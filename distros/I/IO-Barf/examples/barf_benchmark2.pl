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
my $temp5 = File::Temp->new->filename;

# Some data.
my $data = 'x' x 1000;

# Benchmark (10s).
cmpthese(-10, {
        'File::Raw' => sub {
                require File::Raw;
                File::Raw->import('spew') if ! defined &file_spew;
                file_spew($temp1, $data);
                unlink $temp1;
        },
        'File::Slurp' => sub {
                require File::Slurp;
                File::Slurp::write_file($temp2, $data);
                unlink $temp2;
        },
        'IO::Any' => sub {
                require IO::Any;
                IO::Any->spew($temp3, $data);
                unlink $temp3;
        },
        'IO::Barf' => sub {
                require IO::Barf;
                IO::Barf::barf($temp4, $data);
                unlink $temp5;
        },
        'Path::Tiny' => sub {
                require Path::Tiny;
                Path::Tiny::path($temp5)->spew($data);
                unlink $temp5;
        },
});

# Output like this:
# X270, Intel(R) Core(TM) i5-6300U CPU @ 2.40GHz
#                Rate  Path::Tiny     IO::Any    IO::Barf File::Slurp   File::Raw
# Path::Tiny   5755/s          --        -37%        -66%        -70%        -84%
# IO::Any      9204/s         60%          --        -46%        -52%        -74%
# IO::Barf    16907/s        194%         84%          --        -12%        -53%
# File::Slurp 19162/s        233%        108%         13%          --        -47%
# File::Raw   35860/s        523%        290%        112%         87%          --