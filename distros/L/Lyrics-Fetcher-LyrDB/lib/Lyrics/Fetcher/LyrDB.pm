package Lyrics::Fetcher::LyrDB;

use warnings;
use strict;
use Carp;
use LWP::Simple;

=head1 NAME

Lyrics::Fetcher::LyrDB - The great new Lyrics::Fetcher::LyrDB!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
our $AGENT = "Perl/Lyric::Fetcher::LyrDB $VERSION";

=head1 NAME

Lyrics::Fetcher::LyrDB - Get song lyrics from www.LyrDB.com

=head1 SYNOPSIS

  use Lyrics::Fetcher;
  print Lyrics::Fetcher->fetch("<artist>","<song>","LyrDB");

  # or, if you want to use this module directly without Lyrics::Fetcher's
  # involvement:
  use Lyrics::Fetcher::LyrDB;
  print Lyrics::Fetcher::LyricDB->fetch('<artist>', '<song>');


=head1 DESCRIPTION

This module uses LyrDB's web services to get song lyrics from 
www.lyrdb.com.  It's designed to be called by Lyrics::Fetcher, but can be 
used directly if you'd prefer.  This module makes use of the LWP::Simple
module, which you most likely already have.

=head1 FUNCTIONS

=over 4

=item I<trim>($string)

Helper function that trims starting and ending spaces from the string.

=cut

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~s/^\s+$//;
	return $string;
}

=back

=over 4

=item I<fetch>($artist, $song)

Fetch lyrics for the requested song.

=cut

sub fetch 
{
    
    	my $self = shift;
    	my ( $artist, $song ) = @_;
    	my $result = undef;
	my @number = ();
   	my $url = undef;

    	# reset the error var, change it if an error occurs.
    	$Lyrics::Fetcher::Error = 'OK';	
    
	unless ($artist && $song) 
	{
        	carp($Lyrics::Fetcher::Error = 
        	    'fetch() called without artist and song');

        	return;
	}
   
	# Get index of song.
	$url = "http://webservices.lyrdb.com/lookup.php?" .
		"q=$artist|$song&for=match&agent=iSing";

	$result = get $url;

	if(!defined $result)
	{
		carp($Lyrics::Fetcher::Error =
			'fetch() could not query LyrDB.');
		return;
	}
	
	# Let's pick the first one and give LyrDB a query on it.
	$result = trim $result;
	@number = $result =~ /(\d+)\\/;

	if(!scalar(@number))
	{
		$Lyrics::Fetcher::Error =
			"No id number found in query response.";
		return;
	}

	$url = "http://www.lyrdb.com/getlyr.php?q=$number[0]";

	$result = get $url;
	
	if($result =~ /error:\d\d\d/)
	{
		$result = $result =~ /\n+(.+)/;
		$Lyrics::Fetcher::Error = $result;
		return;
	}

    	# looks like it worked:
	$Lyrics::Fetcher::Error = 'OK';

    	return $result;


}



1;
__END__

=back

=head1 AUTHOR

Joshua Soles, C<< <jbsoles at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lyrics-fetcher-lyrdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lyrics-Fetcher-LyrDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lyrics::Fetcher::LyrDB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lyrics-Fetcher-LyrDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lyrics-Fetcher-LyrDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lyrics-Fetcher-LyrDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Lyrics-Fetcher-LyrDB>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Joshua Soles, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
# End of Lyrics::Fetcher::LyrDB
