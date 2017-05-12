package Dist::Zilla::Plugin::LintPrereqs;

our $DATE = '2016-03-04'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with 'Dist::Zilla::Role::InstallTool';

use namespace::autoclean;

has lint_prereqs_options => (is=>'rw');

sub setup_installer {
    my ($self) = @_;

    my $opts = $self->lint_prereqs_options // '';
    my $cmd = "lint-prereqs" . (length($opts) ? " $opts" : "");

    system $cmd;
    if ($?) {
        $self->log_fatal("lint-prereqs failed ($?)");
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Run lint-prereqs during build

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::LintPrereqs - Run lint-prereqs during build

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Plugin::LintPrereqs (from Perl distribution Dist-Zilla-Plugin-LintPrereqs), released on 2016-03-04.

=head1 SYNOPSIS

In F<dist.ini>:

 [LintPrereqs]
 ;lint_prereqs_options = ...

=head1 DESCRIPTION

This plugin will run L<lint-prereqs> during the InstallTool phase (after all
files has been gathered/munged). If linting succeeds, the build continues.
Otherwise, the build is aborted.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-LintPrereqs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-LintPrereqs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-LintPrereqs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lint-prereqs> in L<App::LintPrereqs> distribution.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
