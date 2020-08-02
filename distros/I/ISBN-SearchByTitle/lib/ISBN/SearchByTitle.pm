package ISBN::SearchByTitle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-15'; # DATE
our $DIST = 'ISBN-SearchByTitle'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use HTTP::Tinyish;
use HTTP::UserAgentStr::Util::ByNickname qw(newest_firefox);

my $log_dump = Log::ger->get_logger(category => "dump");

our %SPEC;

$SPEC{search_isbn_by_title} = {
    v => 1.1,
    summary => 'Search ISBN from book title',
    description => <<'_',

Currently implemented by a web search for "amazon book hardcover <title>",
followed by "amazon book paperback <title>" if the first one fails. Then get the
first amazon.com URL, download the URL, and try to extract information from that
page using <pm:WWW::Amazon::Book::Extract>.

_
    args => {
        title => {
            schema => 'str*',
            pos => 0,
            req => 1,
        },
    },
};
sub search_isbn_by_title {
    require URI::Escape;

    my %args = @_;

    my $title = $args{title};

    my $res;
    my $resmeta = {};
    for my $searchq (
        "amazon book hardcover $title",
        "amazon book paperback $title",
    ) {
        #my $url = "https://www.bing.com/search?q=imdb+".URI::Escape::uri_escape($q)); # returns "No result"
        #my $url = "https://duckduckgo.com/?q=imdb+".URI::Escape::uri_escape($q); # doesn't contain any result, only script sections including boxes
        #my $url = "https://www.google.com/search?q=imdb+".URI::Escape::uri_escape($q); # cannot even connect
        my $url = "https://id.search.yahoo.com/search?p=".URI::Escape::uri_escape($searchq); # thank god this still works as of 2019-12-23
        log_trace "Search URL: $url";

        my $http_res = HTTP::Tinyish->new(agent => newest_firefox())->get($url);
        $log_dump->trace("%s", $http_res->{content});
        unless ($http_res->{success}) {
            log_warn "Couldn't get search URL %s: %s - %s",
                $url, $http_res->{status}, $http_res->{reason};
            next;
        }
        my $ct = $http_res->{content};

        my $amazon_url;
        if ($ct =~ m!(https%3a%2f%2fwww.amazon.com.+?)"!) {
            $amazon_url = URI::Escape::uri_unescape($1);
            log_trace "Found Amazon URL in search result: %s", $amazon_url;
        } else {
            log_warn "Didn't find any amazon.com search result, skipped";
            next;
        }

        $http_res = HTTP::Tinyish->new(agent => newest_firefox())->get($amazon_url);
        $log_dump->trace("%s", $http_res->{content});
        unless ($http_res->{success}) {
            log_warn "Couldn't get Amazon URL %s: %s - %s",
                $url, $http_res->{status}, $http_res->{reason};
            next;
        }
        $ct = $http_res->{content};

        require WWW::Amazon::Book::Extract;
        my $extract_res = WWW::Amazon::Book::Extract::parse_amazon_book_page(
            page_content => $ct,
        );

        if (my $isbn = $extract_res->[2]{isbn13} || $extract_res->[2]{isbn10}) {
            $res = $isbn;
            $resmeta->{'func.amazon_raw'} = $ct;
            $resmeta->{'func.amazon_meta'} = $extract_res->[2];
            last;
        }
    }

    [200, "OK", $res, $resmeta];
}

1;
# ABSTRACT: Search ISBN from book title

__END__

=pod

=encoding UTF-8

=head1 NAME

ISBN::SearchByTitle - Search ISBN from book title

=head1 VERSION

This document describes version 0.002 of ISBN::SearchByTitle (from Perl distribution ISBN-SearchByTitle), released on 2020-04-15.

=head1 FUNCTIONS


=head2 search_isbn_by_title

Usage:

 search_isbn_by_title(%args) -> [status, msg, payload, meta]

Search ISBN from book title.

Currently implemented by a web search for "amazon book hardcover <title>",
followed by "amazon book paperback <title>" if the first one fails. Then get the
first amazon.com URL, download the URL, and try to extract information from that
page using L<WWW::Amazon::Book::Extract>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<title>* => I<str>


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

Please visit the project's homepage at L<https://metacpan.org/release/ISBN-SearchByTitle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ISBN-SearchByTitle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ISBN-SearchByTitle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
