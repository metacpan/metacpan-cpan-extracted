package sugar;

use strict ();
use warnings ();
use feature ();
use Method::Signatures::Simple::ParseKeyword ();
use Exporter ();
sub import {
    my $class = shift;
    my $caller = caller;
    my %args = @_;

    strict->import;
    warnings->import;
    Method::Signatures::Simple::ParseKeyword->import(into => $caller);
}

1;
