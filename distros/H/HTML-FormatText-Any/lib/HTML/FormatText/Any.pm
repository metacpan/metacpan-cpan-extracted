package HTML::FormatText::Any;

our $DATE = '2019-01-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(html2text);

our %SPEC;

$SPEC{html2text} = {
    v => 1.1,
    summary => 'Render HTML as text using one of multiple backends',
    description => <<'_',

Backends are tried in the following order (order is chosen based on rendering
quality):

* <pm:HTML::FormatText::Elinks> (using external program 'elinks')
* <pm:HTML::FormatText::Links> (using external program 'links')
* <pm:HTML::FormatText::W3m> (using external program 'w3m')
* <pm:HTML::FormatText::Lynx> (using external program 'lynx')
* <pm:HTML::FormatText::WithLinks::AndTables>

_
    args => {
        html => {
            schema => 'str*',
            req => 1,
            tags => ['category:input'],
            pos => 0,
            cmdline_src => 'stdin_or_files',
        },
        # XXX option to customize order of backends
    },
    links => [
        {url => 'prog:html2text', summary => 'CLI for this module'},
        {url => 'prog:html2txt', summary => 'a simpler HTML rendering utility which basically just strips HTML tags from HTML source code'},
    ],
    'cmdline.skip_format' => 1,
};
sub html2text {
    require File::Which;

    my %args = @_;
    my $html = $args{html} or return [400, "Please specify html"];

  ELINKS:
    {
        last unless File::Which::which("elinks");
        log_trace "Trying to render HTML using elinks ...";
        require HTML::FormatText::Elinks;
        my $text = HTML::FormatText::Elinks->format_string($html);
        unless (defined $text) {
            log_trace "Couldn't render using elinks, ".
                "trying another backend";
            last;
        }
        return [200, "OK (elinks)", $text];
    }

  LINKS:
    {
        last unless File::Which::which("links");
        log_trace "Trying to render HTML using links ...";
        require HTML::FormatText::Links;
        my $text = HTML::FormatText::Links->format_string($html);
        unless (defined $text) {
            log_trace "Couldn't render using links, ".
                "trying another backend";
            last;
        }
        return [200, "OK (links)", $text];
    }

  W3M:
    {
        last unless File::Which::which("w3m");
        log_trace "Trying to render HTML using w3m ...";
        require HTML::FormatText::W3m;
        my $text = HTML::FormatText::W3m->format_string($html);
        unless (defined $text) {
            log_trace "Couldn't render using w3m, ".
                "trying another backend";
            last;
        }
        return [200, "OK (w3m)", $text];
    }

  LYNX:
    {
        last unless File::Which::which("lynx");
        log_trace "Trying to render HTML using lynx ...";
        require HTML::FormatText::Lynx;
        my $text = HTML::FormatText::Lynx->format_string($html);
        unless (defined $text) {
            log_trace "Couldn't render using lynx, ".
                "trying another backend";
            last;
        }
        return [200, "OK (lynx)", $text];
    }

    # fallback
    log_trace "Rendering HTML using HTML::FormatText::WithLinks::AndTables ...";
    require HTML::FormatText::WithLinks::AndTables;
    my $text = HTML::FormatText::WithLinks::AndTables->convert($html);
    [200, "OK (HTML::FormatText::WithLinks::AndTables)", $text];
}

1;
# ABSTRACT: Render HTML as text using one of multiple backends

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormatText::Any - Render HTML as text using one of multiple backends

=head1 VERSION

This document describes version 0.001 of HTML::FormatText::Any (from Perl distribution HTML-FormatText-Any), released on 2019-01-14.

=head1 FUNCTIONS


=head2 html2text

Usage:

 html2text(%args) -> [status, msg, payload, meta]

Render HTML as text using one of multiple backends.

Backends are tried in the following order (order is chosen based on rendering
quality):

=over

=item * L<HTML::FormatText::Elinks> (using external program 'elinks')

=item * L<HTML::FormatText::Links> (using external program 'links')

=item * L<HTML::FormatText::W3m> (using external program 'w3m')

=item * L<HTML::FormatText::Lynx> (using external program 'lynx')

=item * L<HTML::FormatText::WithLinks::AndTables>

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<html>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTML-FormatText-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTML-FormatText-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-FormatText-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<html2text>. CLI for this module.

L<html2txt>. a simpler HTML rendering utility which basically just strips HTML tags from HTML source code.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
