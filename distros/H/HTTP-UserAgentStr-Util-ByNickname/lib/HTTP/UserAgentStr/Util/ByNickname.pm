package HTTP::UserAgentStr::Util::ByNickname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-01'; # DATE
our $DIST = 'HTTP-UserAgentStr-Util-ByNickname'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

our @nicknames = qw(
                       newest_firefox
                       newest_firefox_linux
                       newest_firefox_win
                       newest_chrome
                       newest_chrome_linux
                       newest_chrome_win
               );

use Exporter qw(import);
our @EXPORT_OK = @nicknames;
our %EXPORT_TAGS = (all => \@nicknames);

sub _get {
    require HTTP::BrowserDetect;
    require Versioning::Scheme::Dotted;
    require WordList::HTTP::UserAgentString::Browser::Firefox;

    my $nickname = shift;

    my @ua0;
    my $wl = WordList::HTTP::UserAgentString::Browser::Firefox->new;
    $wl->each_word(
        sub {
            my $orig = shift;
            my $ua = HTTP::BrowserDetect->new($orig);
            push @ua0, {
                orig => $orig,
                os => $ua->os,
                firefox => $ua->firefox,
                chrome => $ua->chrome,
                version => $ua->browser_version || '0.0',
            };
        });
    #use DD; dd \@ua0;

    my @ua;
    if ($nickname eq 'newest_firefox') {
        my $os = $^O eq 'MSWin32' ? 'windows' : 'linux';
        @ua = sort { Versioning::Scheme::Dotted->cmp_version($b->{version}, $a->{version}) }
            grep { $_->{firefox} && ($_->{os}//'') eq $os } @ua0;
    } elsif ($nickname eq 'newest_firefox_linux') {
        @ua = sort { Versioning::Scheme::Dotted->cmp_version($b->{version}, $a->{version}) }
            grep { $_->{firefox} && ($_->{os}//'') eq 'linux' } @ua0;
    } elsif ($nickname eq 'newest_firefox_win') {
        @ua = sort { Versioning::Scheme::Dotted->cmp_version($b->{version}, $a->{version}) }
            grep { $_->{firefox} && ($_->{os}//'') eq 'windows' } @ua0;
    } elsif ($nickname eq 'newest_chrome') {
        my $os = $^O eq 'MSWin32' ? 'windows' : 'linux';
        @ua = sort { Versioning::Scheme::Dotted->cmp_version($b->{version}, $a->{version}) }
            grep { $_->{chrome} && ($_->{os}//'') eq $os } @ua0;
    } elsif ($nickname eq 'newest_chrome_linux') {
        @ua = sort { Versioning::Scheme::Dotted->cmp_version($b->{version}, $a->{version}) }
            grep { $_->{chrome} && ($_->{os}//'') eq 'linux' } @ua0;
    } elsif ($nickname eq 'newest_chrome_win') {
        @ua = sort { Versioning::Scheme::Dotted->cmp_version($b->{version}, $a->{version}) }
            grep { $_->{chrome} && ($_->{os}//'') eq 'windows' } @ua0;
    } else {
        die "BUG: Unknown nickname";
    }

    $ua[0]{orig};
}

our %cache;
sub newest_firefox       { $cache{newest_firefox}       //= _get("newest_firefox") }
sub newest_firefox_linux { $cache{newest_firefox_linux} //= _get("newest_firefox_linux") }
sub newest_firefox_win   { $cache{newest_firefox_win}   //= _get("newest_firefox_win") }
sub newest_chrome        { $cache{newest_chrome}        //= _get("newest_chrome") }
sub newest_chrome_linux  { $cache{newest_chrome_linux}  //= _get("newest_chrome_linux") }
sub newest_chrome_win    { $cache{newest_chrome_win}    //= _get("newest_chrome_win") }

1;
# ABSTRACT: Get popular HTTP User-Agent string by nickname

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::UserAgentStr::Util::ByNickname - Get popular HTTP User-Agent string by nickname

=head1 VERSION

This document describes version 0.003 of HTTP::UserAgentStr::Util::ByNickname (from Perl distribution HTTP-UserAgentStr-Util-ByNickname), released on 2020-05-01.

=head1 SYNOPSIS

 use HTTP::UserAgentStr::Util::ByNickname qw(
                       newest_firefox
                       newest_firefox_linux
                       newest_firefox_win
                       newest_chrome
                       newest_chrome_linux
                       newest_chrome_win
 );

 say newest_firefox_linux();

Sample output (at the time of this writing):

 Mozilla/5.0 (X11; Linux x86_64; rv:66.0) Gecko/20100101 Firefox/66.0

=head1 DESCRIPTION

=head2 newest_firefox

=head2 newest_firefox_linux

=head2 newest_firefox_win

=head2 newest_chrome

=head2 newest_chrome_linux

=head2 newest_chrome_win

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HTTP-UserAgentStr-Util-ByNickname>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HTTP-UserAgentStr-Util-ByNickname>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-UserAgentStr-Util-ByNickname>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
