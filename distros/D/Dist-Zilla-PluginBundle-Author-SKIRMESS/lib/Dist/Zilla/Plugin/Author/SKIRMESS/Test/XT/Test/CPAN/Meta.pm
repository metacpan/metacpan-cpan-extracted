package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::CPAN::Meta;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.008';

use Moose;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/release/meta-yaml.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

use namespace::autoclean;

sub test_body {
    my ($self) = @_;

    return <<'TEST_BODY';
use Test::CPAN::Meta 0.12;

meta_yaml_ok();
TEST_BODY
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
