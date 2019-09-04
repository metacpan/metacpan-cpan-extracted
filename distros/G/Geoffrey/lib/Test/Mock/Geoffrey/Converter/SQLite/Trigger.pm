package Test::Mock::Geoffrey::Converter::SQLite::Trigger;

use utf8;
use 5.016;
use strict;
use warnings;

$Test::Mock::Geoffrey::Converter::SQLite::Trigger::VERSION = '0.000204';

use parent 'Geoffrey::Role::ConverterType';

sub list { return [ { name => 'Trigger 1' }, { name => 'Trigger 2' }, ]; }

sub information {
    my ($self) = shift;
    return shift;
}

1;