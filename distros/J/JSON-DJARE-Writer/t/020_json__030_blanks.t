#!perl

use strict;
use warnings;

use Test::Most;
use JSON;
use JSON::DJARE::Writer;

my $writer = JSON::DJARE::Writer->new(
    djare_version => '0.0.2',
    meta_version  => '0.1.1',
    meta_from     => 0,
);

# Spec doesn't allow defined but null keys for many fields

my $error_implicit = $writer->error(1);

for (qw/id code detail/) {
    ok( ( !exists $error_implicit->{'error'}->{$_} ),
        "implicit: omitted empty $_" );
}

my $error_explicit = $writer->error(
    1,
    id     => undef,
    code   => undef,
    detail => undef
);

for (qw/id code detail/) {
    ok( ( !exists $error_explicit->{'error'}->{$_} ),
        "explicit: omitted empty $_" );
}

done_testing();
