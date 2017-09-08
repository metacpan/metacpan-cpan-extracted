package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Kwalitee;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.009';

use Moose;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/release/kwalitee.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

use namespace::autoclean;

sub test_body {
    my ($self) = @_;

    return <<'TEST_BODY';
use Test::More 0.88;
use Test::Kwalitee 'kwalitee_ok';

# Module::CPANTS::Analyse does not find the LICENSE in scripts that don't end in .pl
kwalitee_ok(qw{-has_license_in_source_file -has_abstract_in_pod});

done_testing();
TEST_BODY
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
