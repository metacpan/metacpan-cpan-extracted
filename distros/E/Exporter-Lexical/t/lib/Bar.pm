package Bar;
use strict;
use warnings;

use Exporter::Lexical ();

our $imported;

my $import = Exporter::Lexical::build_exporter({
    -exports => [ qw(bar) ],
});

sub import {
    $imported = 1;
    goto $import;
}

sub bar { "BAR" }

1;
