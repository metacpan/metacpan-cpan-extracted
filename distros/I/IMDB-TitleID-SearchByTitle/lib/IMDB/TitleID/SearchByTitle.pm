package IMDB::TitleID::SearchByTitle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-15'; # DATE
our $DIST = 'IMDB-TitleID-SearchByTitle'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;
use LWP::Simple;

my $log_dump = Log::ger->get_logger(category => "dump");

our %SPEC;

$SPEC{search_imdb_title_id_by_title} = {
    v => 1.1,
    summary => 'Try to find IMDB title ID for a movie title',
    args => {
        title => {
            schema => 'str*',
            pos => 0,
            req => 1,
        },
    },
};
sub search_imdb_title_id_by_title {
    require URI::Escape;

    my %args = @_;

    my $title = $args{title};

    #my $url = "https://www.bing.com/search?q=imdb+".URI::Escape::uri_escape($q)); # returns "No result"
    #my $url = "https://duckduckgo.com/?q=imdb+".URI::Escape::uri_escape($q); # doesn't contain any result, only script sections including boxes
    #my $url = "https://www.google.com/search?q=imdb+".URI::Escape::uri_escape($q); # cannot even connect
    my $url = "https://id.search.yahoo.com/search?p=imdb+".URI::Escape::uri_escape($title); # thank god this still works as of 2019-12-23
    log_trace "IMDB search URL: $url";
    my $html = get $url;
    $log_dump->trace($html);
    $html =~ m!imdb\.com/title/(.+?)/!
        or return [500, "Cannot get IMDB title ID from web search 'imdb $title'"];
    my $tt = $1;

    [200, "OK", $tt];
}

1;
# ABSTRACT: Try to find IMDB title ID for a movie title

__END__

=pod

=encoding UTF-8

=head1 NAME

IMDB::TitleID::SearchByTitle - Try to find IMDB title ID for a movie title

=head1 VERSION

This document describes version 0.002 of IMDB::TitleID::SearchByTitle (from Perl distribution IMDB-TitleID-SearchByTitle), released on 2020-04-15.

=head1 FUNCTIONS


=head2 search_imdb_title_id_by_title

Usage:

 search_imdb_title_id_by_title(%args) -> [status, msg, payload, meta]

Try to find IMDB title ID for a movie title.

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

Please visit the project's homepage at L<https://metacpan.org/release/IMDB-TitleID-SearchByTitle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-IMDB-TitleID-SearchByTitle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=IMDB-TitleID-SearchByTitle>

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
