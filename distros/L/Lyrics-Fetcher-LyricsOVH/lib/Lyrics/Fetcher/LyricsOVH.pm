package Lyrics::Fetcher::LyricsOVH;

# $Id$

use 5.008000;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use Carp;

my $haveLyricsFetcher = 0;
eval "use Lyrics::Fetcher (qw(\$AGENT)); \$haveLyricsFetcher = 1; 1";

our $VERSION = 0.01;

# the HTTP User-Agent we'll send:
our $AGENT = ($haveLyricsFetcher && defined $Lyrics::Fetcher::AGENT)
        ? $Lyrics::Fetcher::AGENT
        : "Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0";

$Lyrics::Fetcher::Error = 'OK'  unless ($haveLyricsFetcher);

sub fetch {
    my $self = shift;
    my ($artist, $song) = @_;

    # reset the error var, change it if an error occurs.
    $Lyrics::Fetcher::Error = 'OK';

    unless ($artist && $song) {
        carp($Lyrics::Fetcher::Error
                = 'fetch() called without artist and song');
        return;
    }

    $artist =~ s#\s*\/.*$##;    #ONLY USE 1ST ARTIST, IF MORE THAN ONE!
    $artist =~ s/\s+/\%20/g;
    $artist =~ s/[^a-z0-9\%]//gi;

    $song   =~ s/\s+/\%20/g;
    $song   =~ s/[^a-z0-9\%]//gi;

    # Their URLs look like e.g.:
    # https://api.lyrics.ovh/v1/Dire%20straits/heavy%sfuel%s
    my $url = "https://api.lyrics.ovh/v1/${artist}/$song";

    my $ua = LWP::UserAgent->new(
        ssl_opts => { verify_hostname => 0, },
    );
    $ua->timeout(10);
    $ua->agent($AGENT);
    $ua->protocols_allowed(['https']);
    $ua->cookie_jar( {} );
    push @{ $ua->requests_redirectable }, 'GET';
    (my $referer = $url) =~ s{^(\w+)\:\/\/}{};
    my $protocol = $1;
    $referer =~ s{\/.+$}{\/};
    my $host = $referer;
    $host =~ s{\/$}{};
    $referer = $protocol . '://' . $referer;
    my $req = new HTTP::Request 'GET' => $url;
    $req->header(
        'Accept' =>
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language'           => 'en-US,en;q=0.5',
        'Accept-Encoding'           => 'gzip, deflate',
        'Connection'                => 'keep-alive',
        'Upgrade-insecure-requests' => 1,
        'Host'                      => $host,
    );

    my $res = $ua->request($req);

    if ($res->is_success) {
        my $lyrics = _parse($res->decoded_content);
        return $lyrics;
    } else {
        if ($res->status_line =~ /^404/) {
            $Lyrics::Fetcher::Error = 'Lyrics not found';
            return;
        } else {
            carp($Lyrics::Fetcher::Error
                = "Failed to retrieve $url (".$res->status_line.')');
            return;
        }
    }
}

# Allow user to specify a different user-agent:
sub agent {
    if (defined $_[1]) {
        $AGENT = $_[1];
    } else {
        return $AGENT;
    }
}

# Internal use only functions:

sub _parse {
    my $html = shift;

    if (my ($goodbit) = $html =~
        m{\{\"lyrics\"\:\"([^\"]+)\"}msi)
    {
        my $text = '';
        # convert literal "\" followed by "r" or "n", etc. to "\r" or "\n" characters respectively:
        eval "\$text = \"$goodbit\";";

        # fix apparent site bug where they use "\n\n" where they appear to mean "\r\n" (excess double-lines):
        $text =~ s/\n\n/\n/gs;
        # normalize Windowsey \r\n sequences:
        $text =~ s/\r+//gs;
        # strip off pre & post padding with spaces:
        $text =~ s/^ +//mg;
        $text =~ s/ +$//mg;
        # clear up repeated blank lines:
        $text =~ s/(\R){2,}/\n\n/gs;
        # and remove any blank top lines:
        $text =~ s/^\R+//s;
        $text =~ s/\R\R+$/\n/s;
        $text .= "\n"  unless ($text =~ /\n$/s);
        # now fix up for either Windows or Linux/Unix:
        $text =~ s/\R/\r\n/gs  if ($^O =~ /Win/);

        return $text;
    } else {
        carp "Failed to identify lyrics on result page";
        return;
    }

} # end of sub parse

1;

__END__

=head1 NAME

Lyrics::Fetcher::LyricsOVH - Get song lyrics from api.lyrics.ovh.

=head1 SYNOPSIS

    #!/usr/bin/perl

    use Lyrics::Fetcher;
    print Lyrics::Fetcher->fetch("<artist>","<song>","ApiLyricsOVH");

    # or, if you want to use this module directly without Lyrics::Fetcher's involvement:

    use Lyrics::Fetcher::ApiLyricsOVH;
    print Lyrics::Fetcher::ApiLyricsOVH->fetch("<artist>", "<song>");


=head1 DESCRIPTION

This module tries to get song lyrics from api.lyrics.ovh.  It's designed to
be called by Lyrics::Fetcher, but can be used directly if you'd prefer.

=head1 INTERFACE

=over 4

=item fetch($artist, $title)

Attempts to fetch the lyrics for the given artist and title from api.lyrics.ovh.

Returns lyrics as a string, or an empty string, if not found.

=item agent([$useragent_string])

Set the desired user-agent (ie. browser name) to pass to the lyrics sites -
some require you to look like a valid web browser in order to respond in order to
prevent their sites from being "scraped" by programs, such as this.  If not set,
the current default is:
"Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0"

If no argument is passed, it returns the current user-agent string in effect.

=back

=head1 SPECIAL GLOBAL VARIABLES

=over 4

=item $Lyrics::Fetcher::Error

Returns a description of the last error that occurred when failing to fetch 
lyrics for various reasons, or "OK" if last operation successful.

=item $Lyrics::Fetcher::ApiLyricsOph::VERSION

The current version# of Lyrics::Fetcher::ApiLyricsOph

=back

=head1 BUGS

Probably.  If you find any, please let me know.  If api.lyrics.ovh change their
site much, this module may well stop working.  If you find any songs which
have lyrics listed on the api.lyrics.ovh site, but for which this module is
unable to fetch lyrics, please let me know also.

Please report any bugs or feature requests to 
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lyrics-Fetcher-ApiLyricsOVH>.
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 AUTHOR

David Precious C<< <davidp@preshweb.co.uk> >> (CPAN Id: BIGPRESH)

=head1 ACKNOWLEDGEMENTS

Original version contributed by Jim Turner in RT 133624..

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

Legal disclaimer: I have no connection with the owners of api.lyrics.ovh.
Lyrics fetched by this script may be copyrighted by the authors, it's up to 
you to determine whether this is the case, and if so, whether you are entitled 
to request/use those lyrics.  You will almost certainly not be allowed to use
the lyrics obtained for any commercial purposes.

=cut
