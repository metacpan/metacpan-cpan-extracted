package Lyrics::Fetcher::LyricsDownload;

use strict;

use Encode;
use HTML::TokeParser;
use LWP::Simple qw($ua get);
use vars qw($VERSION);

$VERSION = '0.01';

sub fetch {
    my($self,$artist, $title) = @_;

    $Lyrics::Fetcher::Error = 'OK';

    unless ($artist && $title) {
        $Lyrics::Fetcher::Error = 'fetch() called without artist and song title';
        return;
    }

	$artist =~ s/ ((^\w)|(\s\w))/\U$1/xg;
	$artist =~ s/\ /\-/g;
	$artist =~ s/\"//g;
	$artist =~ s/\'//g;
	$artist =~ s/\,//g;
	$artist =~ s/\://g;
	$artist =~ s/\?//g;
	$artist =~ s/\.//g;
	$artist =~ s/\&/and/g;

	$title =~ s/ ((^\w)|(\s\w))/\U$1/xg;
	$title  =~ s/\ /\-/g;
	$title  =~ s/\"//g;
	$title  =~ s/\'//g;
	$title  =~ s/\,//g;
	$title  =~ s/\://g;
	$title  =~ s/\?//g;
	$title  =~ s/\.//g;
	$title  =~ s/\&/and/g;

	my $lyrics = "";
	my $url = "http://www.lyricsdownload.com/".$artist."-".$title."-lyrics.html";
	$url = lc($url);
	my $content = get($url);
	if($content eq "") { $Lyrics::Fetcher::Error = 'Content empty'; return; }
	utf8::decode($content);
	my $parser = HTML::TokeParser->new(\$content);
	$parser->{textify} = {'br'};

	while( my $token = $parser->get_token() ) {
		if($token->[0] eq "S") {
			if($token->[1] eq "font") {
				if($token->[4] =~ /\"txt_1\"/) {
					$lyrics = $parser->get_trimmed_text('/font');
					
					   if($lyrics =~ /Translated title:/) {}
					elsif($lyrics =~ /back to \-\>/) {}
					else {
						$lyrics =~ s/\[BR\]\ /\n/g;
						$lyrics =~ s/\[BR\]/\n/g;
						last;
					}
				}
			}
		}
	}

	return $lyrics;
}

1;

=head1 NAME

Lyrics::Fetcher::LyricsDownload - Get song lyrics from lyricsdownload.com

=head1 SYNOPSIS

  use Lyrics::Fetcher;
  print Lyrics::Fetcher->fetch("<artist>","<song>","LyricsDownload");

  # or, if you want to use this module directly without Lyrics::Fetcher's
  # involvement (be aware that using Lyrics::Fetcher is the recommended way):
  use Lyrics::Fetcher::LyricsDownload;
  print Lyrics::Fetcher::LyricsDownload->fetch('<artist>', '<song>');


=head1 DESCRIPTION

This module tries to get song lyrics from lyricsdownload.com.  It's designed 
to be called by Lyrics::Fetcher, and this is the recommended usage, but it can 
be used directly if you'd prefer.

=head1 INTERFACE

=over 4

=item fetch($artist, $title)

Attempts to fetch lyrics.

=back


=head1 BUGS

if you find any bugs, please let me know.


=head1 COPYRIGHT AND LICENCE

Copyright (C) 2008 by Rick Blevins

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.


=head1 AUTHOR

Rick Blevins E<lt>rick816us@comcast.netE<gt>


=head1 LEGAL DISCLAIMER

Legal disclaimer: I have no connection with the owners of lyricsdownload.com.
Lyrics fetched by this script may be copyrighted by the authors, it's up to 
you to determine whether this is the case, and if so, whether you are entitled 
to request/use those lyrics.  You will almost certainly not be allowed to use
the lyrics obtained for any commercial purposes.

=cut
