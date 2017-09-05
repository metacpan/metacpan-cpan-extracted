package Dist::Zilla::Plugin::Author::SKIRMESS::TravisCI;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.008';

use Moose;

with qw(
  Dist::Zilla::Role::BeforeBuild
);

use Carp;
use Path::Tiny;

sub mvp_multivalue_args { return (qw( travis_ci_ignore_perl )) }

has travis_ci_ignore_perl => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

use namespace::autoclean;

sub before_build {
    my ($self) = @_;

    my $travis_yml = "language: perl\nperl:\n";

    my @perl = grep { defined && !m{ ^ \s* $ }xsm } $self->_get_perl_version_to_check_with_travis();
    croak 'no perl versions selected for TravisCI' if !@perl;

    for my $perl (@perl) {
        $travis_yml .= "  - '$perl'\n";
    }

    $travis_yml .= <<'TRAVIS_YML';
before_install:
  - export AUTOMATED_TESTING=1
install:
  - cpanm --quiet --installdeps --notest --skip-satisfied --with-develop .
script:
  - perl Makefile.PL && make test
  - test -d xt/author && prove -lr xt/author
  - make manifest
  - test -d xt/release && prove -lr xt/release
TRAVIS_YML

    path('.travis.yml')->spew($travis_yml);

    return;
}

sub _get_perl_version_to_check_with_travis {
    my ($self) = @_;

    my @perl_available = qw(5.26 5.24 5.22 5.20 5.18 5.16 5.14 5.12 5.10 5.8);

    my %perl_to_skip;
  PERL:
    for my $perl ( @{ $self->travis_ci_ignore_perl } ) {
        next PERL if !defined $perl;
        $perl_to_skip{$perl} = 1;
    }

    my @perl;
    for my $perl (@perl_available) {
        if ( !exists $perl_to_skip{$perl} ) {
            push @perl, $perl;
        }
    }

    return @perl;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
