package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Changes;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.008';

use Moose;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/release/changes.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

use namespace::autoclean;

sub test_body {
    my ($self) = @_;

    return <<'TEST_BODY';
use Test::CPAN::Changes;

changes_ok();
TEST_BODY
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
