package TidyTestUtils;

use 5.010001;
use warnings;
use strict;

use Test::More;

use base 'Exporter';

our @EXPORT_OK = qw(
    remove_specificity
    messages_are
);
our @EXPORT = @EXPORT_OK;

sub remove_specificity {
    my $clean = shift;

    $clean =~ s/HTML Tidy for HTML5 (for .+ )?\bversion \d+\.\d+\.\d+/TIDY/;

    return $clean;
}

sub messages_are {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tidy     = shift;
    my $expected = shift;
    my $msg      = shift;

    return is_deeply( [ map { $_->as_string } $tidy->messages ], $expected, $msg );
}

1;
