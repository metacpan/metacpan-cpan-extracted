package Test::Games::SMTNocturne::Demons;
use strict;
use warnings;
use Exporter 'import';

use Games::SMTNocturne::Demons;
use Test::More;

our @EXPORT = ('fusion_is', 'set_fusion_options');

my $FUSION_OPTIONS = {};

sub set_fusion_options {
    $FUSION_OPTIONS = $_[0];
}

sub fusion_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($demon1, $demon2, $expected) = @_;

    my $fused = eval {
        Games::SMTNocturne::Demons::fuse($demon1, $demon2, $FUSION_OPTIONS)
    };

    die $@ if $@ && $@ !~ /\bnyi\b/;
    local $TODO = $@ if $@;

    if ($fused) {
        is($fused->name, $expected);
    }
    else {
        is(undef, $expected);
    }
}

1;
