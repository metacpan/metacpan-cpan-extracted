package Mail::LMLM::Render::HTML;
$Mail::LMLM::Render::HTML::VERSION = '0.6807';
use strict;
use warnings;

use vars qw(@ISA);

use Mail::LMLM::Render;

@ISA = qw(Mail::LMLM::Render);

sub initialize
{
    my $self = shift;

    my $out_file = shift;

    $self->{'out'} = $out_file;

    return 0;
}

sub _htmlize_onechar
{
    my $c = shift;

    if ( $c eq "<" )
    {
        return "\&lt;";
    }
    elsif ( $c eq ">" )
    {
        return "\&gt;";
    }
    elsif ( $c eq '&' )
    {
        return "\&amp;";
    }
    elsif ( $c eq "\n" )
    {
        return "<br />";
    }
    else
    {
        return $c;
    }
}

sub _htmlize
{
    my $text = shift;

    $text =~ s/(<|>|\&|\n)/_htmlize_onechar($1)/ge;

    return $text;
}

sub text
{
    my $self = shift;

    my $text = shift;

    my $style;

    if ( scalar(@_) )
    {
        $style = shift;
    }
    else
    {
        $style = {};
    }

    my $out = _htmlize($text);

    if ( $style->{'bold'} )
    {
        $out = "<b>" . $out . "</b>";
    }
    if ( $style->{'underline'} )
    {
        $out = "<u>" . $out . "</u>";
    }
    if ( $style->{'italic'} )
    {
        $out = "<i>" . $out . "</i>";
    }

    print { *{ $self->{'out'} } } $out;

    return 0;
}

sub newline
{
    my $self = shift;

    print { *{ $self->{'out'} } } "<br />\n";
}

sub indent_inc
{
    my $self = shift;

    print { *{ $self->{'out'} } } "\n<div class=\"indent\">\n";

    return 0;
}

sub indent_dec
{
    my $self = shift;

    print { *{ $self->{'out'} } } "\n</div>\n";

    return 0;
}

sub start_link
{
    my $self = shift;

    my $url = shift;

    print { *{ $self->{'out'} } } "<a href=\"$url\">";

    return 0;
}

sub end_link
{
    my $self = shift;

    print { *{ $self->{'out'} } } "</a>";

    return 0;
}

sub start_section
{
    my $self = shift;

    my $title = shift;

    my $options;

    if ( scalar(@_) )
    {
        $options = shift;
    }
    else
    {
        $options = {};
    }

    my $o = $self->{'out'};

    my $id_attr = "";
    if ( exists( $options->{'id'} ) )
    {
        $id_attr = " id=\"" . $options->{'id'} . "\"";
    }

    print { *{$o} } "<h2${id_attr}>";
    if ( exists( $options->{'title_url'} ) )
    {
        print { *{$o} } "<a href=\"" . $options->{'title_url'} . "\">";
    }
    $self->text($title);
    if ( exists( $options->{'title_url'} ) )
    {
        print { *{$o} } "</a>";
    }
    print { *{$o} } "</h2>";
    print { *{$o} } "\n\n";

    return 0;
}

sub start_para
{
    my $self = shift;

    print { *{ $self->{'out'} } } ("<p>\n");

    return 0;
}

sub end_para
{
    my $self = shift;

    print { *{ $self->{'out'} } } ("\n</p>\n");

    return 0;
}

sub end_section
{
    my $self = shift;

    print { *{ $self->{'out'} } } ("\n\n");

    return 0;
}

sub start_document
{
    my $self = shift;

    my $head_title = shift;

    my $body_title = shift;

    $head_title = _htmlize($head_title);

    my $o = $self->{'out'};

    print { *{$o} } <<"EOF" ;
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US" lang="en-US">
<head>
<title>$head_title</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" href="./style.css" type="text/css" />
</head>
<body>
EOF

    print { *{$o} } ("<h1>");

    $self->text($body_title);

    print { *{$o} } ("</h1>\n\n");

    return 0;
}

sub end_document
{
    my $self = shift;

    print { *{ $self->{'out'} } } ( "\n" . "</body>\n" . "</html>\n" );

    return 0;
}

sub horizontal_line
{
    my $self = shift;

    print { *{ $self->{'out'} } } ("\n\n<hr />\n\n");

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::LMLM::Render::HTML - backend for rendering HTML.

=head1 VERSION

version 0.6807

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

This is a derived class of L<Mail::LMLM::Render> that renders HTML.

=head1 METHODS

=head2 start_document($head_title, $body_title)

=head2 end_document()

=head2 start_section($title [, { 'title_url' => $url } ])

=head2 end_section()

=head2 start_para()

=head2 end_para()

=head2 text($text [, $style])

=head2 newline()

=head2 start_link($url)

=head2 end_link()

=head2 indent_inc()

=head2 indent_dec()

=head2 horizontal_line()

=head2 email_address($account,$host)

=head2 url($url [, $inside])

=head2 para($text [, $style])

See the documentation at L<Mail::LMLM::Render>.

=head2 initialize()

Construction method. For internal use.

=head1 AUTHOR

Shlomi Fish L<http://www.shlomifish.org/>.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Mail-LMLM>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Mail-LMLM>

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

L<https://github.com/shlomif/perl-mail-lmlm>

  git clone git://github.com/shlomif/perl-mail-lmlm.git

=head1 AUTHOR

Shlomi Fish

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-mail-lmlm/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
