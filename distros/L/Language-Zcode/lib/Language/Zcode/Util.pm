package Language::Zcode::Util;

use strict;
use warnings;

use Exporter;
use vars qw(@EXPORT @ISA %Constants @Memory);
@ISA = qw(Exporter);
@EXPORT = qw(%Constants @Memory);

# Utilities used both by parser and translator

sub get_byte_at { $Memory[$_[0]]; }
sub set_byte_at { $Memory[$_[0]] = $_[1]; }
sub get_word_at { 256*$Memory[$_[0]] + $Memory[$_[0]+1]; }

1;
