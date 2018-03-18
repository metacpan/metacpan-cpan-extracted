package TidyTestUtils;

use 5.010001;
use warnings;
use strict;

use base 'Exporter';

our @EXPORT_OK = qw(
    remove_specificity
);
our @EXPORT = @EXPORT_OK;

sub remove_specificity {
    my $clean = shift;

    $clean =~ s/HTML Tidy for HTML5 for \w+ version \d+\.\d+\.\d+/TIDY/;

    return $clean;
}

1;
