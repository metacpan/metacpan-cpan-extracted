package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Spelling;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.005';

use Moose;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/author/pod-spell.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

use List::MoreUtils qw(uniq);

sub mvp_multivalue_args { return (qw( stopwords )) }

has stopwords => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

use namespace::autoclean;

sub test_body {
    my ($self) = @_;

    my $test_body = <<'TEST_BODY';
use Test::Spelling 0.12;
use Pod::Wordlist;

add_stopwords(<DATA>);

all_pod_files_spelling_ok(qw( bin lib ));
__DATA__
TEST_BODY

    my @stopwords = $self->_get_stopwords();

    $test_body .= join "\n", @stopwords, q{};
    return $test_body;
}

sub _get_stopwords {
    my ($self) = @_;

    my @stopwords = grep { defined && !m{ ^ \s* $ }xsm } @{ $self->stopwords };

    push @stopwords, split /\s/xms, join q{ }, @{ $self->zilla->authors };

    return uniq sort @stopwords;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
