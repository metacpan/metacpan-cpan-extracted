use 5.14.0;
use strict;
use warnings;

package Dist::Zilla::Plugin::Author::CSSON::GithubActions;

# ABSTRACT: Ease creation of common Github Actions workflows
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0106';

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::CSSON::GithubActions - Ease creation of common Github Actions workflows



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="http://cpants.cpanauthors.org/release/CSSON/Dist-Zilla-Plugin-Author-CSSON-GithubActions-0.0106"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Dist-Zilla-Plugin-Author-CSSON-GithubActions/0.0106" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Author-CSSON-GithubActions%200.0106"><img src="http://badgedepot.code301.com/badge/cpantesters/Dist-Zilla-Plugin-Author-CSSON-GithubActions/0.0106" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-84.6%-orange.svg" alt="coverage 84.6%" />
</p>

=end html

=head1 VERSION

Version 0.0106, released 2020-12-26.

=head1 SYNOPSIS

In dist.ini:

    [Author::CSSON::GithubActions::Workflow::TestWithMakefile]
    ; set on.push.branches to an empty list
    clear_on_push_branches = 1

    ; set on.pull_request.branches to an empty list
    clear_on_pull_request_branches = 1

    ; add branches to on.push.branches
    on_pull_request_branches = 'this-branch'
    on_pull_request_branches = 'that-other-branch'

    ; add branches to on.pull_request.branches
    on_pull_request_branches = 'my-pr-branch'
    on_pull_request_branches = 'feature-branch'

    ; replace jobs.perl-job.strategy.matrix.os
    matrix_os = ubuntu-latest
    matrix_os = ubuntu-16.04

    ; replace jobs.perl-job.strategy.matrix.perl-version
    perl_version = 5.32
    perl_version = 5.24
    perl_version = 5.18

=head1 STATUS

This plugin is very early in development. It might be released in a non-author namespace at a later stage.

=head1 DESCRIPTION

This distribution is a framework for creating re-usable Github Actions workflows. GitHub's documentation about Actions is located at L<http://docs.github.com/en/free-pro-team@latest/actions>.

The core of it is the L<Dist::Zilla::Role::Author::CSSON::GithubActions> role.

Included in this distribution is an example workflow, L<Dist::Zilla::Plugin::Author::CSSON::GithubActions::Workflow::TestWithMakefile>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::TravisCI>

=item *

L<http://docs.github.com/en/free-pro-team@latest/actions>

=item *

L<https://perlmaven.com/setup-github-actions>

=back

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
