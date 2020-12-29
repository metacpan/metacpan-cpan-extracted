use 5.14.0;
use strict;
use warnings;

package Dist::Zilla::Plugin::Author::CSSON::GithubActions::Workflow::TestWithMakefile;

# ABSTRACT: Workflow for testing with Makefile.PL
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0106';

use Moose;
use Types::Standard qw/ArrayRef/;
with qw/
    Dist::Zilla::Role::Author::CSSON::GithubActions
/;

has run_before => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    traits => ['Array'],
    documentation => q{Adds one or more steps before installing Perl modules},
    handles => {
        all_run_before => 'elements',
        has_run_before => 'count',
    },
);

sub mvp_multivalue_args {
    qw/
        run_before
    /;
};

sub workflow_filename { 'workflow-test-with-makefile.yml' }

sub distribution_name { 'Dist-Zilla-Plugin-Author-CSSON-GithubActions' }

sub parse_custom_parameters {
    my $self = shift;
    my $yaml = shift;

    if ($self->has_run_before) {
        splice @{ $yaml->{'jobs'}{'perl-job'}{'steps'} }, 1, 0, map { { run => $_ } } $self->all_run_before;
    }
    return $yaml;

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::CSSON::GithubActions::Workflow::TestWithMakefile - Workflow for testing with Makefile.PL

=head1 VERSION

Version 0.0106, released 2020-12-26.

=head1 SYNOPSIS

In dist.ini:

    [Author::CSSON::GithubActions::Workflow::TestWithMakefile]
    run_before = apt-get install nano

=head1 DESCRIPTION

This is an example workflow for L<Dist::Zilla::Plugin::Author::CSSON::GithubActions>. It is based
on L<https://perlmaven.com/setup-github-actions>.

The actual workflow is defined in C<share/workflow-test-with-makefile.yml>.

In addition to the parameters defined in L<Dist::Zilla::Role::Author::CSSON::GithubActions>, this workflow class adds one
additional parameter: C<run_before>. This parameter allows for the insertion of one or more steps before any Perl testing is being done.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-Author-CSSON-GithubActions>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-Author-CSSON-GithubActions>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
