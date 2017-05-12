package Mail::LMLM::Render;

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

=head1 NAME

Mail::LMLM::Render - rendering backend for LMLM

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

=cut
