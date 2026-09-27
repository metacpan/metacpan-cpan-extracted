package Games::Cards::Troika::Util;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-07-15'; # DATE
our $DIST = 'Games-Cards-Troika-Util'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{troika_list_cards} = {
    v => 1.1,
    summary => 'Return the list of cards',
    args => {
        lang => {schema => ['str*', in=>['eng', 'ind', 'fra'], default=>'eng']},
        descriptive => {schema => 'bool*'},
        detail => {schema => 'bool*'},
    },
    args_rels => {
        choose_one => [qw/descriptive detail/],
    },
};
sub troika_list_cards {
    my %args = @_;

    my $lang = $args{lang} // 'eng';

    require TableData::Games::Cards::Troika;
    my $t = TableData::Games::Cards::Troika->new;

    my @rows;
    while ($t->has_next_row) {
        my $row = $t->get_next_row_hashref;
        push @rows, $row;
    }

    if ($args{detail}) {
        1;
    } elsif ($args{descriptive}) {
        @rows = map { $_->{"${lang}_descriptive_name"} } @rows;

    } else {
        @rows = map { $_->{"${lang}_short_name"} } @rows;
    }

    [200, "OK", \@rows];
}

1;
# ABSTRACT: Utilities related to the Anak Bos Troika card game

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Cards::Troika::Util - Utilities related to the Anak Bos Troika card game

=head1 VERSION

This document describes version 0.001 of Games::Cards::Troika::Util (from Perl distribution Games-Cards-Troika-Util), released on 2026-07-15.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 troika_list_cards

Usage:

 troika_list_cards(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the list of cards.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<descriptive> => I<bool>

(No description)

=item * B<detail> => I<bool>

(No description)

=item * B<lang> => I<str> (default: "eng")

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Games-Cards-Troika-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Games-Cards-Troika-Util>.

=head1 SEE ALSO

Website of publisher. L<https://www.engaginc.com/> .

Homepage for the game. L<https://www.engaginc.com/products/anak-bos-troika/> .

Some additional materials for the game (instruction, logo, box mockup). L<https://github.com/berdikaritc/engaginc-productinfo-troika> .

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar

perlancar <perlancar@gmail.com>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Cards-Troika-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
