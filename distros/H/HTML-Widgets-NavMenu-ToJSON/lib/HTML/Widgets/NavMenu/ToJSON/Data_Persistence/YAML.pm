package HTML::Widgets::NavMenu::ToJSON::Data_Persistence::YAML;

use 5.008;
use strict;
use warnings FATAL => 'all';

use parent 'HTML::Widgets::NavMenu::ToJSON::Data_Persistence';

use YAML::XS ();


our $VERSION = '0.0.7';

__PACKAGE__->mk_acc_ref([ qw( _filename ) ]);

sub _init
{
    my ($self, $args) = @_;

    $self->_filename($args->{filename});

    return;
}



sub load
{
    my $self = shift;

    my $data;

    if (!eval
    {
        ($data) = YAML::XS::LoadFile($self->_filename());

        1;
    })
    {
        $data = $self->_calc_initial_data();
    }

    $self->_data(
        $data
    );

    return;
}


sub save
{
    my $self = shift;

    YAML::XS::DumpFile(
        $self->_filename,
        $self->_data
    );

    return;
}


1; # End of HTML::Widgets::NavMenu::ToJSON::Data_Persistence::YAML

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::ToJSON::Data_Persistence::YAML - YAML-based persistence
for L<HTML::Widgets::NavMenu::ToJSON> .

=head1 VERSION

version 0.0.7

=head1 SYNOPSIS

See HTML::Widgets::NavMenu::ToJSON .

=head1 DESCRIPTION

This is a sub-class of L<HTML::Widgets::NavMenu::ToJSON::Data_Persistence>
for providing coarse-grained persistence using a serialised YAML store as
storage.

=head1 VERSION

Version 0.0.7

=head1 SUBROUTINES/METHODS

=head2 HTML::Widgets::NavMenu::ToJSON::Data_Persistence::YAML->new({ filename => '/path/to/filename.yml' });

Initializes the persistence store with the YAML file in $args->{filename} .

=head2 $self->load()

Loads the data from the file.

=head2 $self->save()

Saves the data from the file.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-widgets-navmenu-tojson at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Widgets-NavMenu-ToJSON>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::Widgets::NavMenu::ToJSON::Data_Persistence::YAML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Widgets-NavMenu-ToJSON>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Widgets-NavMenu-ToJSON>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Widgets-NavMenu-ToJSON>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Widgets-NavMenu-ToJSON/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Shlomi Fish.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Widgets-NavMenu-ToJSON or by
email to bug-xml-grammar-vered@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc HTML::Widgets::NavMenu::ToJSON

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/HTML-Widgets-NavMenu-ToJSON>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/HTML-Widgets-NavMenu-ToJSON>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Widgets-NavMenu-ToJSON>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/HTML-Widgets-NavMenu-ToJSON>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/HTML-Widgets-NavMenu-ToJSON>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/HTML-Widgets-NavMenu-ToJSON>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/HTML-Widgets-NavMenu-ToJSON>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Widgets-NavMenu-ToJSON>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Widgets-NavMenu-ToJSON>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Widgets::NavMenu::ToJSON>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-widgets-navmenu-tojson at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Widgets-NavMenu-ToJSON>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://bitbucket.org/shlomif/perl-html-widgets-navmenu>

  hg clone ssh://hg@bitbucket.org/shlomif/perl-html-widgets-navmenu

=cut
