#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Module.
use Benchmark qw(cmpthese);
use IO::Any;
use IO::Barf;
use File::Slurp qw(write_file);
use File::Temp;

# Temporary files.
my $temp1 = File::Temp->new->filename;
my $temp2 = File::Temp->new->filename;
my $temp3 = File::Temp->new->filename;

# Some data.
my $data = 'x' x 1000;

# Benchmark (10s).
cmpthese(-10, {
        'File::Slurp' => sub {
                write_file($temp3, $data);
                unlink $temp3;
        },
        'IO::Any' => sub {
                IO::Any->spew($temp2, $data);
                unlink $temp2;
        },
        'IO::Barf' => sub {
                barf($temp1, $data);
                unlink $temp1;
        },
});

# Output like this:
#                Rate     IO::Any File::Slurp    IO::Barf
# IO::Any      6382/s          --        -24%        -48%
# File::Slurp  8367/s         31%          --        -32%
# IO::Barf    12268/s         92%         47%          --