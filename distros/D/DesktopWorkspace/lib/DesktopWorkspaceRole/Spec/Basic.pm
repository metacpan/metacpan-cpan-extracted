package DesktopWorkspaceRole::Spec::Basic;

use strict;
use warnings;

use Role::Tiny;
use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-03-29'; # DATE
our $DIST = 'DesktopWorkspace'; # DIST
our $VERSION = '1.0.0'; # VERSION

# constructor
requires 'new';

# other required methods
requires 'items';
requires 'kde_activity';
requires 'new_browser_window';

# mixin
#with 'Role::TinyCommons::Iterator::Resettable';
#with 'Role::TinyCommons::Collection::GetItemByPos';

# provides

###

1;
# ABSTRACT: Required methods for all DesktopWorkspace::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

DesktopWorkspaceRole::Spec::Basic - Required methods for all DesktopWorkspace::* modules

=head1 VERSION

This document describes version 1.0.0 of DesktopWorkspaceRole::Spec::Basic (from Perl distribution DesktopWorkspace), released on 2026-03-29.

=head1 DESCRIPTION

 category                     method name                   note
 --------                     -----------                   -------
 instantiating                new(%args)

 properties                   items([ $val ])
                              kde_activity([ $val ])
                              new_browser_window([ $val ])

=head1 ROLES MIXED IN

None.

=head1 REQUIRED METHODS

=head2 new

Usage:

 my $dw = DesktopWorkspace::Foo->new([ %args ]);

Constructor. Must accept a pair of argument names and values.

=head2 items

Get or set items.

=head2 kde_activity

Get or set the C<kde_activity> property.

=head2 new_browser_window

Get or set the C<new_browser_window> property.

=head1 PROVIDED METHODS

None.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DesktopWorkspace>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DesktopWorkspace>.

=head1 SEE ALSO

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
