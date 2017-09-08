package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Pod::No404s;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.009';

use Moose;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/author/pod-no404s.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

use namespace::autoclean;

sub test_body {
    my ($self) = @_;

    return <<'TEST_BODY';
if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

use Test::Pod::No404s;

all_pod_files_ok();
TEST_BODY
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
