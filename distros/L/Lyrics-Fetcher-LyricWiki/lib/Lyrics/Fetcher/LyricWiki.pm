package Lyrics::Fetcher::LyricWiki;

# $Id$

use 5.005000;
use strict;
use warnings;

our $VERSION = '0.20';

=head1 NAME

Lyrics::Fetcher::LyricWiki - DEPRECATED now LyricWiki is dead

=head1 SYNOPSIS

    # No synopsis is useful here, as LyricWiki has shutdown, so this dist
    # remains only as a stub to warn.

=head1 DESCRIPTION

This was a fetcher for L<Lyrics::Fetcher> to fetch lyrics from www.lyricwiki.org
which was taken over by Fandom.

Fandom killed off LyricWiki on 21st September 2020; this fetcher now exists
only as a stub to return an error, for the sake of anyone already using it
- there is absolutely no point in installing it afresh.

For the closure reasons, see the L<closure notice from Fandom|https://web.archive.org/web/20200830142257/https://lyrics.fandom.com/wiki/LyricWiki>

=head1 FUNCTIONS    

=over 4

=item I<fetch>($artist, $song)

Fetch lyrics for the requested song.

=cut

sub fetch {
    my $self = shift;
    $Lyrics::Fetcher::Error = 'LyricsWiki no longer exists';
}



1;
__END__

=back

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.


=head1 AUTHOR

David Precious E<lt>davidp@preshweb.co.ukE<gt>



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2020 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
