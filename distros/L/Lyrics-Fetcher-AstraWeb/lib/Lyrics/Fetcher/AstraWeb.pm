package Lyrics::Fetcher::AstraWeb;

# AstraWeb - lyrics.astraweb.com implementation
#
# Copyright (C) 2003 Sir Reflog <reflog@mail15.com>
# All rights reserved.
#
# Maintainership of Lyrics::Fetcher transferred in Feb 07 to BIGPRESH
# (David Precious <davidp@preshweb.co.uk>)

# $Id: AstraWeb.pm 333 2008-04-24 18:53:53Z davidp $

use strict;
use warnings;
use WWW::Mechanize;
use vars qw($VERSION);

$VERSION = '0.33';

sub fetch {
    my($self,$artist, $title) = @_;
    my $agent = WWW::Mechanize->new();
    my($sartist) = join ("+", split(/ /, $artist));
    my($stitle) = join ("+", split(/ /, $title));
    
    # quote regexp meta-characters to avoid breakage:
    $title = quotemeta $title;
    $artist = quotemeta $artist;
    
    $agent->get("http://search.lyrics.astraweb.com/?word=$sartist+$stitle");
    
    if(grep { $_->text() =~ /$title/ }@{$agent->links}) {
        $agent->follow_link(text_regex => qr((?-xism:$title)));
        
        if(grep { $_->text() =~ /Printable/ }@{$agent->links}) {
		    $agent->follow_link(text_regex => qr((?-xism:Printable)));
        } else {
            $Lyrics::Fetcher::Error = 'Bad page format';
            return;
        }
    } else {
        $Lyrics::Fetcher::Error = 'Cannot find such title';
        return;
    }
    
    return $agent->content =~  /<blockquote>(.*)<\/blockquote>/ && $1;
}

1;

=head1 NAME

Lyrics::Fetcher::AstraWeb - Get song lyrics from lyrics.astraweb.com

=head1 SYNOPSIS

  use Lyrics::Fetcher;
  print Lyrics::Fetcher->fetch("<artist>","<song>","AstraWeb");

  # or, if you want to use this module directly without Lyrics::Fetcher's
  # involvement (be aware that using Lyrics::Fetcher is the recommended way):
  use Lyrics::Fetcher::AstraWeb;
  print Lyrics::Fetcher::AstraWeb->fetch('<artist>', '<song>');


=head1 DESCRIPTION

This module tries to get song lyrics from lyrics.astraweb.com.  It's designed 
to be called by Lyrics::Fetcher, and this is the recommended usage, but it can 
be used directly if you'd prefer.

=head1 INTERFACE

=over 4

=item fetch($artist, $title)

Attempts to fetch lyrics.

=back


=head1 BUGS

Probably. If you find any bugs, please let me know.


=head1 COPYRIGHT AND LICENCE

Copyright (C) 2007 by David Precious

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.


=head1 AUTHOR

David Precious E<lt>davidp@preshweb.co.ukE<gt>


=head1 LEGAL DISCLAIMER

Legal disclaimer: I have no connection with the owners of astraweb.com.
Lyrics fetched by this script may be copyrighted by the authors, it's up to 
you to determine whether this is the case, and if so, whether you are entitled 
to request/use those lyrics.  You will almost certainly not be allowed to use
the lyrics obtained for any commercial purposes.

=cut
