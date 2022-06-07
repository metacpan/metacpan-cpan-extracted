package HTML::Widgets::NavMenu::HeaderRole;
$HTML::Widgets::NavMenu::HeaderRole::VERSION = '1.1000';
use strict;
use warnings;

use parent 'HTML::Widgets::NavMenu';

require HTML::Widgets::NavMenu::Iterator::NavMenu::HeaderRole;

sub _get_nav_menu_traverser
{
    my $self = shift;

    return HTML::Widgets::NavMenu::Iterator::NavMenu::HeaderRole->new(
        $self->_get_nav_menu_traverser_args() );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::HeaderRole - A Specialized HTML::Widgets::NavMenu
sub-class

=head1 VERSION

version 1.1000

=head1 DESCRIPTION

This module is constructed and invoked similarly to HTML::Widgets::NavMenu.
The only difference is that it is meaningful to specify C<"header"> as the
value of the C<'role'>.

In that case, the link or bolded label will be rendered within its own
C<E<lt>h2E<gt>> header. The HTML will look something like this:

    </ul>
    <h2>
    <a href="../me/" title="About Myself">About Me</a>
    </h2>
    <ul>

An example of this use can be found on the Perl Beginners Site
( L<http://perl-begin.org/> ).

=head1 SYNOPOSIS

Mostly the same as L<HTML::Widgets::NavMenu> except for the ability to
specify C<'role' =E<gt> "header"> as one of the node attributes.

=head1 SEE ALSO

L<HTML::Widgets::NavMenu> for the complete documentation of the super-class.

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org> .

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Widgets-NavMenu>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Widgets-NavMenu>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Widgets-NavMenu>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Widgets-NavMenu>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Widgets-NavMenu>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Widgets::NavMenu>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-widgets-navmenu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Widgets-NavMenu>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu>

  git clone git://github.com/shlomif/perl-HTML-Widgets-NavMenu.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
