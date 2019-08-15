package Test::Mock::Geoffrey::Converter::SQLite::Functions;

use utf8;
use 5.016;
use strict;
use warnings;

$Test::Mock::Geoffrey::Converter::SQLite::Functions::VERSION = '0.000103';

use parent 'Geoffrey::Role::ConverterType';

sub list { return [ { name => 'Function 1' }, { name => 'Function 2' }, ]; }

sub information { my ($self) = shift; return shift; }

1;
