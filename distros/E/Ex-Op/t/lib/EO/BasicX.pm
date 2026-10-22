package EO::BasicX;
use strict;
use warnings;
use Exporter 'import';

our $VERSION   = '1.00';
our @EXPORT    = qw(f);
our @EXPORT_OK = qw(g $s @a %h *gl &amp length ghost f2 Other::thing);

sub f      { 'f' }
sub g      { 'g' }
sub amp    { 'amp' }
sub length { 'mine' }
sub f2     { 'f2' }
sub gl     { 'gl' }
sub EO::BasicX::Other::thing { 'pkg thing' }

our $s  = 's';
our @a  = (1, 2);
our %h  = (k => 'v');
our $gl = 'gl scalar';

1;
