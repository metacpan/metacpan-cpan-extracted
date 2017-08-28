package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Version;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.005';

use Moose;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/author/test-version.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

use namespace::autoclean;

sub test_body {
    my ($self) = @_;

    return <<'TEST_BODY';
use Test::More 0.88;
use Test::Version 0.04 qw( version_all_ok ), {
    consistent  => 1,
    has_version => 1,
    is_strict   => 0,
    multiple    => 0,
};

version_all_ok;
done_testing();
TEST_BODY
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
