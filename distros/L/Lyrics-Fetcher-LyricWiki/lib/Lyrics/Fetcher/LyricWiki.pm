package Lyrics::Fetcher::LyricWiki;

# $Id$

use 5.005000;
use strict;
use warnings;
use LWP::UserAgent;
use Carp;

our $VERSION = '0.10';

# the HTTP User-Agent we'll send:
our $AGENT = "Perl/Lyrics::Fetcher::LyricWiki $VERSION";


=head1 NAME

Lyrics::Fetcher::LyricWiki - Get song lyrics from www.LyricWiki.org

=head1 SYNOPSIS

  use Lyrics::Fetcher;
  print Lyrics::Fetcher->fetch("<artist>","<song>","LyricWiki");

  # or, if you want to use this module directly without Lyrics::Fetcher's
  # involvement:
  use Lyrics::Fetcher::LyricWiki;
  print Lyrics::Fetcher::LyricWiki->fetch('<artist>', '<song>');


=head1 DESCRIPTION

This module tries to get song lyrics from www.lyricwiki.org.  It's designed to
be called by Lyrics::Fetcher, but can be used directly if you'd prefer.


=head1 FUNCTIONS    

=over 4

=item I<fetch>($artist, $song)

Fetch lyrics for the requested song.

=cut

sub fetch {
    
    my $self = shift;
    my ( $artist, $song ) = @_;
    
    # reset the error var, change it if an error occurs.
    $Lyrics::Fetcher::Error = 'OK';
    
    unless ($artist && $song) {
        carp($Lyrics::Fetcher::Error = 
            'fetch() called without artist and song');
        return;
    }

    my $ua = LWP::UserAgent->new();
    $ua->agent($AGENT);

    # We'll fetch the edit page for the lyrics, as it provides nice clean text
    # to parse out, without ringtone adverts etc which made the HTML
    # unparseable.
    my $url = join ':', map { s/\s+/_/; $_ } ($artist, $song);
    my $resp = $ua->get("http://lyrics.wikia.com/index.php?action=edit"
        . "&title=$url");
    
    if (!$resp->is_success) {
        if ($resp->status_line =~ /404/) {
            # Lyrics for this song not found (this doesn't seem to happen, we
            # get a 200 anyway, handled below...)
            $Lyrics::Fetcher::Error = 'Lyrics not found';
            return;
        } else {
            # Something else wrong, so return HTTP error description
            $Lyrics::Fetcher::Error = "Failed to fetch - " . $resp->status_line;
            return;
        }
    }

    # Check it wasn't the "page doesn't exist yet" error page
    if ($resp->content =~ /a link to a page that doesn't exist yet/) {
        $Lyrics::Fetcher::Error = 'Lyrics not found';
        return;
    }
   
    # If it was a redirect, we should follow it; just call ourselves again.
    # TODO: make sure we don't end up with infinite recursion if there's a
    # redirect loop.
    if (my($newartist, $newtitle) = 
        $resp->content =~ m{\#REDIRECT \s+ \[\[ ([^:]+) : ([^:]+) \]\] }xi)
    {
        return __PACKAGE__->fetch($newartist, $newtitle);
    }

    # OK, parse the HTML:
    my $html = $resp->content;
    my ($lyrics) = $html =~ m{ 
        &lt;lyrics?(?:&gt;|>) 
        (.+?)
        &lt;/lyrics?(?:&gt;|>)
        }xms;
    
    if ($lyrics) {
        # Looks like we got something usable:
        $Lyrics::Fetcher::Error = 'OK';
        return $lyrics;
    } else {
        $Lyrics::Fetcher::Error = 'No lyrics parsed from page';
        return;
    }
}



1;
__END__

=back

=head1 BUGS

Probably.  Coded in about an hour whilst drinking cold lager :)
If you find any bugs, please let me know.


=head1 THANKS

Thanks to Sean Colombo for creating www.LyricWiki.org, and thanks to Wikia.com
for taking on the project and keeping it alive.


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.


=head1 DISCLAIMER

Lyrics are copyright their original owners and/or record companies who purchased
the rights to them.  Lyrics accessed programmatically via this module should be
used for educational purposes only, and should not be distributed/re-published
without authorisation.  You are responsible for your usage of this module.


=head1 AUTHOR

David Precious E<lt>davidp@preshweb.co.ukE<gt>



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2010 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
