package HTML::Acronyms;
$HTML::Acronyms::VERSION = '0.0.4';
use strict;
use warnings;
use 5.014;

use Carp ();

use Moo;

has 'dict' => (
    is       => 'ro',
    required => 1,
);

sub abbr
{
    my ( $self, $args ) = @_;

    my $key     = $args->{key};
    my $no_link = $args->{no_link};
    if ( exists $args->{link} )
    {
        $no_link = ( !$args->{link} );
    }

    my $rec = $self->dict->{$key};

    if ( !defined $rec )
    {
        Carp::confess("unknown key '$key'!");
    }

    my $tag = qq{<abbr title="$rec->{title}">$rec->{abbr}</abbr>};

    return +{ html => ( $no_link ? $tag : qq{<a href="$rec->{url}">$tag</a>} ),
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Acronyms - Generate HTML5/etc. markup for acronyms

=head1 VERSION

version 0.0.4

=head1 SYNOPSIS

    my $acro = HTML::Acronyms->new(
        {
            dict => +{
                SQL => {
                    abbr  => "SQL",
                    title => "Structured Query Language",
                    url   => qq#https://en.wikipedia.org/wiki/SQL#,
                },
                WDYM => {
                    abbr  => "WDYM",
                    title => "what do you mean",
                    url   => "https://en.wiktionary.org/wiki/WDYM",
                },
            }
        }
    );

    is(
        scalar( $acro->abbr( { key => 'WDYM', no_link => 1 } )->{html} ),
        qq#<abbr title="what do you mean">WDYM</abbr>#,
        "no_link test",
    );

    is(
        scalar( $acro->abbr( { key => 'SQL', no_link => 0 } )->{html} ),
        qq#<a href="https://en.wikipedia.org/wiki/SQL"><abbr title="Structured Query Language">SQL</abbr></a>#,
        "no_link test",
    );

=head1 DESCRIPTION

Acronyms and other abbreviations can be quite cryptic ("What do you mean by
'WDYM'?") and this module aims to help expanding them in HTML5/XHTML5
documents.

=head1 METHODS

=head2 $acro->dict()

Returns the hash ref that serves as the dictionary for the acronyms.

=head2 $acro->abbr({ key => "SQL", link => 1, no_link => 0,})

Returns a hash ref with an C<'html'> key.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Acronyms>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Acronyms>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Acronyms>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Acronyms>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Acronyms>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Acronyms>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-acronyms at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Acronyms>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/HTML-Acronyms>

  git clone git://github.com/shlomif/HTML-Acronyms.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/HTML-Acronyms/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
