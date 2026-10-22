package Ops::Late;
use strict;
use warnings;
use Ex::Op;

our @EXPORT_OK = qw(late);

BEGIN { Ex::Op::make(late => sub { my ($x) = @_; "late $x" }) }

1;
