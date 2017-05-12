package ExportingModule2;

use strict;
use warnings;
use parent 'Exporter';

our @EXPORT_OK = qw(foo bar);

sub foo {
    return 'called foo';
}

sub bar {
    return 'called bar';
}

1;
