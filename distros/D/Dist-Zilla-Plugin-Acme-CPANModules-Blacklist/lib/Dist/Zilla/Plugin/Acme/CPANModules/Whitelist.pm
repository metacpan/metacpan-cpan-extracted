package Dist::Zilla::Plugin::Acme::CPANModules::Whitelist;

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::AfterBuild',
);

#has author => (is=>'rw'); # not yet
has module => (is=>'rw');
has ignore_on_error => (is=>'rw', default=>sub {1});

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'Dist-Zilla-Plugin-Acme-CPANModules-Blacklist'; # DIST
our $VERSION = '0.002'; # VERSION

sub mvp_multivalue_args { qw(module) }

sub after_build {}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Specify whitelist

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Acme::CPANModules::Whitelist - Specify whitelist

=head1 VERSION

This document describes version 0.002 of Dist::Zilla::Plugin::Acme::CPANModules::Whitelist (from Perl distribution Dist-Zilla-Plugin-Acme-CPANModules-Blacklist), released on 2023-07-09.

=head1 SYNOPSIS

In your F<dist.ini>:

 [Acme::CPANModules::Blacklist]
 module=PERLANCAR::Avoided

 [Acme::CPANModules::Whitelist]
 module=Log::Any

This means that if your dist specifies a prereq to C<Log::Any>, the Blacklist
plugin will not abort build even though the module is listed in one of the
blacklists.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 module

Str. Can be specified more than once. Module name to whitelist.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Acme-CPANModules-Blacklist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Acme-CPANModules-Blacklist>.

=head1 SEE ALSO

L<Acme::CPANModules>

C<Acme::CPANModules::*> modules

L<Dist::Zilla::Plugin::Acme::CPANModules::Blacklist>

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

This software is copyright (c) 2023, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Acme-CPANModules-Blacklist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
