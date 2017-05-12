package Devel::FastProf::Reader;

use strict;
use warnings;

our $VERSION = '0.08';

use Carp;

require XSLoader;
XSLoader::load('Devel::FastProf', $Devel::FastProf::Reader::VERSION);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(%PPID %FPIDMAP %TICKS %COUNT @SRC @FN $TICKS_PER_SECOND read_fastprof);

our (%PPID, %FPIDMAP, %TICKS, %COUNT,
     @SRC, @FN,
     $TICKS_PER_SECOND);

sub read_fastprof {
    (%PPID, %FPIDMAP, %TICKS, %COUNT, @SRC, @FN, $TICKS_PER_SECOND) = ();
    _read_file(shift);
}

1;
