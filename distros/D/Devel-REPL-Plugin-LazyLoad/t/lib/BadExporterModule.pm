package BadExporterModule;

use strict;
use warnings;
use parent 'Exporter';

our @EXPORT_OK = qw(foo bar);

sub foo {
    return 1;
}

sub bar {
    return 2;
}

0; # I want to fail!
