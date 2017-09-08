package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::DistManifest;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.009';

use Moose;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/release/manifest.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

use namespace::autoclean;

sub test_body {
    my ($self) = @_;

    return <<'TEST_BODY';
use Test::DistManifest 1.003;

manifest_ok();
TEST_BODY
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
