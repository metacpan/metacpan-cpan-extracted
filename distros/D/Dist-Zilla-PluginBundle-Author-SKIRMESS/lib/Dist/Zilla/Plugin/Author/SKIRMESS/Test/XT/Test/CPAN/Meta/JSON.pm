package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::CPAN::Meta::JSON;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.005';

use Moose;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/release/meta-json.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

use namespace::autoclean;

sub test_body {
    my ($self) = @_;

    return <<'TEST_BODY';
use Test::CPAN::Meta::JSON;

meta_json_ok();
TEST_BODY
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
