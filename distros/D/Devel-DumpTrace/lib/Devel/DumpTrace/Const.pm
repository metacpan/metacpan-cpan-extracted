package Devel::DumpTrace::Const;
use Exporter;
use strict;
use warnings;

our $VERSION = '0.26';
our @ISA = qw(Exporter);
our @EXPORT = qw/
    DISPLAY_NONE DISPLAY_TERSE DISPLAY_GABBY
    ABBREV_SMART ABBREV_STRONG ABBREV_MILD_SM ABBREV_MILD ABBREV_NONE
    OUTPUT_SUB OUTPUT_PID OUTPUT_TIME OUTPUT_COUNT
    CALLER_PKG CALLER_SUB
/;

# parameters for controlling how much output is produced
use constant DISPLAY_NONE  => 0;  # trace off
use constant DISPLAY_TERSE => 1;  # concise - 1 trace line per stmnt
use constant DISPLAY_GABBY => 4;  # verbose - 2-5 trace lines per stmt
use constant ABBREV_SMART  => 0;  # strong,smart abbrev of long scalars,
use constant ABBREV_STRONG => 1;  # strong abbreviation of long scalars,
use constant ABBREV_MILD_SM => 2; # mild abbreviation      arrays, hashes
use constant ABBREV_MILD   => 3;  # mild abbreviation      arrays, hashes
use constant ABBREV_NONE   => 4;  # no abbreviation

# additional information to include in output
use constant OUTPUT_SUB => !($ENV{DUMPTRACE_NO_SUB} || 0) || 0;
use constant OUTPUT_PID => $ENV{DUMPTRACE_PID} || 0;
use constant OUTPUT_TIME => $ENV{DUMPTRACE_TIME} || 0;
use constant OUTPUT_COUNT => $ENV{DUMPTRACE_COUNT} || 0;

# for interpreting list output of  caller
use constant CALLER_PKG => 0;     # package name
use constant CALLER_SUB => 3;     # current subroutine name

1;
