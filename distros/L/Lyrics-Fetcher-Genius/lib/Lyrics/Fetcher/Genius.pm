package Lyrics::Fetcher::Genius;

use 5.008000;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use HTML::Strip;
use Carp;

our $VERSION = '0.05';

# the HTTP User-Agent we'll send:
our $AGENT
    = "Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0";

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

    # Their URLs look like e.g.:
    # https://genius.com/Dire-straits-heavy-fuel-lyrics
    $artist = ucfirst $artist;
    $song = lc $song;
    (my $url = $artist) =~ s#\/.*$##;
    $url .= "-${song}-lyrics";
    $url =~ s/ +/\-/g;
    $url =~ s/\%20/\-/g;
    $url =~ s/\%\d+//g;
    $url =~ s/\.//g;
    $url =~ s/[^a-zA-Z0-9\.\-]+//g;
    $url = 'https://genius.com/' . $url;

    my $ua = LWP::UserAgent->new(
        timeout           => 10,
        agent             => $AGENT,
        protocols_allowed => ['https'],
        cookie_jar        => {},
        ssl_opts          => { verify_hostname => 0, },
    );
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
                    = "Failed to retrieve $url (" . $res->status_line . ')');
            return;
        }
    }

}

sub _parse {
    my $html = shift;

    if (my ($goodbit)
        = $html =~ m{\<div\s+class\=\"lyrics\"\>(.+)\<\!\-\-\/sse\-\-\>}msi)
    {
        my $hs   = HTML::Strip->new();
        my $text = $hs->parse($goodbit);

        $text =~ s/\s+$//xmgi;

        # finally, clear up excess blank lines:
        $text =~ s/(\r?\n){2,}/\n\n/gs;

        return $text;

    } else {
        carp "Failed to identify lyrics on result page";
        return;
    }

}    # end of sub parse

1;

__END__

=head1 NAME

Lyrics::Fetcher::Genius - Get song lyrics from www.genius.com

=head1 SYNOPSIS

  use Lyrics::Fetcher;
  print Lyrics::Fetcher->fetch("<artist>","<song>","Genius");

  # or, if you want to use this module directly without Lyrics::Fetcher's
  # involvement:
  use Lyrics::Fetcher::Genius;
  print Lyrics::Fetcher::Genius->fetch('<artist>', '<song>');


=head1 DESCRIPTION

This module tries to get song lyrics from www.genius.com.  It's designed to
be called by Lyrics::Fetcher, but can be used directly if you'd prefer.

=head1 INTERFACE

=over 4

=item fetch($artist, $title)

Attempts to fetch lyrics.

=back


=head1 BUGS

Probably.  If you find any, please let me know.  If genius.com change their
site much, this module may well stop working.  If you find any songs which
have lyrics listed on the www.genius.com site, but for which this module is
unable to fetch lyrics, please let me know also.  It seems that the HTML on
the lyrics pages isn't consistent, so it's entirely possible (likely, in fact)
that there are some pages which this script will not be able to parse.


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.


=head1 AUTHOR

David Precious E<lt>davidp@preshweb.co.ukE<gt>

=head1 ACKNOWLEDGEMENTS

Original version contributed by Jim Turner in RT 133592


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

Legal disclaimer: I have no connection with the owners of www.genius.com.
Lyrics fetched by this script may be copyrighted by the authors, it's up to 
you to determine whether this is the case, and if so, whether you are entitled 
to request/use those lyrics.  You will almost certainly not be allowed to use
the lyrics obtained for any commercial purposes.

=cut
