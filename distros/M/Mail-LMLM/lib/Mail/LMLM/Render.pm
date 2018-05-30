package Mail::LMLM::Render;
$Mail::LMLM::Render::VERSION = '0.6805';
use strict;
use warnings;

use vars qw(@ISA);

use Mail::LMLM::Object;

@ISA=qw(Mail::LMLM::Object);

sub para
{
    my $self = shift;

    $self->start_para();
    $self->text(@_);
    $self->end_para();

    return 0;
}

sub url
{
    my $self = shift;

    my $url = shift;

    my $inside;

    if (scalar(@_))
    {
        $inside = shift;
    }
    else
    {
        $inside = $url;
    }

    $self->start_link($url);
    $self->text($inside);
    $self->end_link();

    return 0;
}

sub email_address
{
    my $self = shift;

    my $account = shift;
    my $host = shift;

    $self->start_link("mailto:$account\@$host");
    $self->text("$account\@$host");
    $self->end_link();

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::LMLM::Render - rendering backend for LMLM

=head1 VERSION

version 0.6805

=head1 SYNOPSIS

    use Mail::LMLM::Render::HTML;

    open O, ">out.html";
    my $r = Mail::LMLM::Render::HTML->new(\*O);

    $r->start_document("My Document", "Head Title");

    $r->start_section("Google", { 'title_url' => "http://www.google.com/", });

    $r->para("Google is a very nice search engine.");
    $r->end_section();
    $r->end_document();
    close(O);

=head1 DESCRIPTION

The Mail::LMLM::Render is a base class for rendering hypertext. It is used
by LMLM extensively as a thin layer around the actual format.

To use it open a filehandle, and call the package's B<new> constructor
with a refernce to the filehandle. Afterwards call the B<start_document>
method (documented below), and when you're done call the B<end_document>
method. For each section call B<start_section> and B<end_section>
explicitly.

=head1 VERSION

version 0.6805

=head1 METHODS

=head2 start_document($head_title, $body_title)

Starts the document. $head_title will be displayed at the title of the
Window. $body_title will be displayed as a headline in the main text.

=head2 end_document()

Terminates the document.

=head2 start_section($title [, { 'title_url' => $url } ])

Starts a section titled $title. The second optional paramter contains
options. Currently the following options are available:

=over 4

=item C<'title_url'>

A URL for the section to point to.

=item C<'id'>

An ID for the section heading. (similar to the id="" attribute in XHTML).

=back

=head2 end_section()

Terminates a section.

=head2 start_para()

Starts a paragraph.

=head2 end_para()

Ends the current paragraph.

=head2 text($text [, $style])

Outputs the text $text. $style is an optional reference to a hash that
contains style parameters. A true C<'bold'> value makes the text bold.
A true C<'underline'> value makes the text underline. A true
C<'italic'> value makes the text italic.

=head2 newline()

Outputs a newline.

=head2 start_link($url)

Starts a link to the URL $url.

=head2 end_link()

Terminates the current link.

=head2 indent_inc()

Increases the current indentation.

=head2 indent_dec()

Decreases the current indentation.

=head2 horizontal_line()

Outputs a hard rule to the document.

=head2 email_address($account,$host)

Outputs an E-mail address with a URL. The address is $account@$host.

=head2 url($url [, $inside])

Outputs a hyperlink to the URL $url with a text of $inside (which defaults
to $url if not specified).

=head2 para($text [, $style])

Outputs the text $text with style $style (refer to the text() method)
in its own paragraph.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org> .

=head1 AUTHOR

unknown

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by unknown.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/mail-lmlm/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Mail::LMLM::Render

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Mail-LMLM>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Mail-LMLM>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Mail-LMLM>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Mail-LMLM>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Mail-LMLM>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Mail-LMLM>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/Mail-LMLM>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Mail-LMLM>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Mail::LMLM>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-mail-lmlm at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Mail-LMLM>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/mail-lmlm>

  git clone http://bitbucket.org/shlomif/perl-mail-lmlm/overview

=cut
