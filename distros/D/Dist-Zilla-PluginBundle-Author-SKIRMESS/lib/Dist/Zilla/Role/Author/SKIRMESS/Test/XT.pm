package Dist::Zilla::Role::Author::SKIRMESS::Test::XT;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.009';

use Moose::Role;
with qw(
  Dist::Zilla::Role::BeforeBuild
  Dist::Zilla::Role::Plugin
);

use Carp;
use Path::Tiny;

requires qw(
  filename
  test_body
);

use namespace::autoclean;

sub before_build {
    my ($self) = @_;

    my $filename = path( $self->filename );
    $filename->parent()->mkpath();
    $filename->spew( $self->test_as_string() );

    return;
}

sub test_as_string {
    my ($self) = @_;

    my $test = <<'TEST_HEADER';
#!perl

use 5.006;
use strict;
use warnings;
TEST_HEADER

    $test .= "\n# this test was generated with\n# " . ref($self) . q{ } . $self->VERSION() . "\n\n";

    $test .= $self->test_body();

    return $test;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
