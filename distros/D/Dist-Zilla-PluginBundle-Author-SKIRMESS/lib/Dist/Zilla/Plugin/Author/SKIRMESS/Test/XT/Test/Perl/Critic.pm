package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Perl::Critic;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.008';

use Moose;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/author/critic.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

use Carp;
use Path::Tiny;

use namespace::autoclean;

after 'before_build' => sub {
    my ($self) = @_;

    my $perlcriticrc = path('.perlcriticrc');
    return if -e $perlcriticrc;

    my $perlcriticrc_content = <<'RC';
severity = 1
theme    = core

[-Documentation::RequirePodSections]

[-InputOutput::RequireBriefOpen]

[InputOutput::RequireCheckedSyscalls]
exclude_functions = print

# Broken, complains on .t files
# https://rt.cpan.org/Public/Bug/Display.html?id=84135
[-Modules::RequireVersionVar]

# vim: ts=4 sts=4 sw=4 et: syntax=perl
RC

    $perlcriticrc->spew($perlcriticrc_content);

    return;
};

sub test_body {
    my ($self) = @_;

    return <<'TEST_BODY';
use File::Spec;

use Perl::Critic::Utils qw(all_perl_files);
use Test::More;
use Test::Perl::Critic;

my @dirs = qw(bin lib t xt);

my @ignores = ();

my %ignore = map { $_ => 1 } @ignores;

my @files = grep { !exists $ignore{$_} } all_perl_files(@dirs);

if ( @files == 0 ) {
    BAIL_OUT('no files to criticize found');
}

all_critic_ok(@files);
TEST_BODY
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
