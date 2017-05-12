package MD5::Reverse;

use strict;
use Digest::MD5 qw/md5/;

our $VERSION = '0.01';

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw/\&reverse/;

sub reverse{ reverse( md5($_[0])) }

1;
