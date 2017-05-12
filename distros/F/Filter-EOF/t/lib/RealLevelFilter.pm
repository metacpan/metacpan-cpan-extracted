package RealLevelFilter;
use warnings;
use strict;

use Filter::EOF;
use base 'Exporter';

our @EXPORT = qw(test_export);

sub import {
    my ($class, $caller, @args) = @_;

    Filter::EOF->on_eof_call(sub {
        no strict 'refs';
        ${ $caller . '::COMPILE_TIME' } = 0;
    });

    {   no strict 'refs';
        ${ $caller . '::COMPILE_TIME' } = 1;
    }

    $class->export_to_level(2);
}

sub test_export { 23 }

1;
