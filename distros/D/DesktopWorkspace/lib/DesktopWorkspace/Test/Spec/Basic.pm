package DesktopWorkspace::Test::Spec::Basic;

use strict;
use warnings;

use Data::Clone;
use Role::Tiny::With;

with 'DesktopWorkspaceRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-03-29'; # DATE
our $DIST = 'DesktopWorkspace'; # DIST
our $VERSION = '1.0.0'; # VERSION

my $spec = {
    summary => 'A summary',
    kde_activity => 'foo',
    items => [
        {url => 'https://www.example.com'},
        {file => '/foo'},
        {dir => '/bar'},
        {app_path => '/usr/bin/dolphin'},
    ],
};

sub new {
    my $class = shift;
    bless clone($spec), $class;
}

sub items {
    my $self = shift;
    if (@_) {
        $self->{items} = $_[0];
    } else {
        $self->{items};
    }
}

sub kde_activity {
    my $self = shift;
    if (@_) {
        $self->{kde_activity} = $_[0];
    } else {
        $self->{kde_activity};
    }
}

sub new_browser_window {
    my $self = shift;
    if (@_) {
        $self->{new_browser_window} = $_[0];
    } else {
        $self->{new_browse_window};
    }
}

1;

# ABSTRACT: A test desktop workspace

__END__

=pod

=encoding UTF-8

=head1 NAME

DesktopWorkspace::Test::Spec::Basic - A test desktop workspace

=head1 VERSION

This document describes version 1.0.0 of DesktopWorkspace::Test::Spec::Basic (from Perl distribution DesktopWorkspace), released on 2026-03-29.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DesktopWorkspace>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DesktopWorkspace>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DesktopWorkspace>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
