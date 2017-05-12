package Mediawiki::Wikicopy;

use 5.008006;
use strict;
use warnings;
# Check out UNICODE problem
use LWP::UserAgent;
use Data::Dumper;
use HTML::Extract;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mediawiki::Spider ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.31';


# Preloaded methods go here.



sub new {
        my $package = shift;
        my $self= {
           _uri=> undef,
           _wikiwords=> undef,
           _wikiindex=> undef,
		   _extension=> "html",
                 };
				 
        #return bless({}, $package);
        return bless ($self,$package);
}

sub extension {
	my ($self, $extension)=@_;
	$self->{_extension} = $extension if defined($extension);
	return $self->{_extension};
}


sub seturi {
        my ( $self, $uri ) = @_;
        $self->{_uri} = $uri if defined($uri);
        return $self->{_uri};
}

sub wikiindex{
	# wikiindex; a hash of hashes?
       my ( $self, @wikiindex) = @_;
       @{$self->{_wikiindex}} = @wikiindex if @wikiindex ;
       if( defined(@{$self->{_wikiindex}})) {
                   return @{$self->{_wikiindex}};
           };
}


sub wikiwords{
       my ( $self, @wikiwords) = @_;
       @{$self->{_wikiwords}} = @wikiwords if @wikiwords ;
       if( defined(@{$self->{_wikiwords}})) {
                   return @{$self->{_wikiwords}};
           };
}

sub urlencode {

	  my ($self,$str) = @_;
	  # $str =~ s/%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	  #TODO:URL encode

	  return $str;
}
sub urldecode {

	  my ($self,$str) = @_;
	  $str =~ s/%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

	  return $str;
}

sub makeflatpages{
       my ( $self, $folder) = @_;
	   my @wikiwords=$self->wikiwords();
	print "Wikiwords".Data::Dumper->Dump([@wikiwords])."\n";
	   my $extractor=new HTML::Extract();
	   my $uri=$self->seturi();
	   $uri=~/(.*)\/(.*)\//;
	   my $uriextension=$2;
	   my @categories;
	   foreach my $word (@wikiwords){
		   sleep 7;
		   print "Working on $word with $uri\n";
		   if($word=~/http\:\/\/(.*)/){ # no sucking the whole interweb, please!
			   	print "Looking at $word (ignore) \n";
		   }else { 	# get page, collect categories...
			   	print "Looking at $uri$word (get page) \n";
		   		my $text=$extractor->gethtml($uri.$word,"tagclass=wiki-content");
				#print "$text\n";
				#$text=~s/\"\/$uriextension\/([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)/\"$1\.html/g;
				#my @rawcategories=split(/href=\"([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)\.html/,$text);
				my $ext=$self->extension();
				$text=~s/\"\/$uriextension\/([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)/\"$1\.$ext/g;
				my @rawcategories=split(/href=\"([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)\.$ext/,$text);
				foreach my $category (@rawcategories) {
					$category=~/(^[0-9A-Za-z\-\_\:\%\&\.\,\;\+\#]+)$/;
					if(!$1 eq ""){
					push(@categories,$1);
					}
				}
				if($text =~ /Category:Exclude/){
					print "Not printing $word (excluded)\n";
				} else {
					# Do not have category: files... : in files is bad
					$text=~s/href=\"Category:([0-9A-z\-\_\%\&\.\,\;\+\#]+)/href=\"Category-$1/g;
					# squelch the '[edit]' links
					my $contexturi=$uri;
					$contexturi=~s/details/context/;
					$text=~s/\/confluence\/display\/context\//$contexturi/g;
					my $cleanword=$self->urldecode($word);
					open(FILEHANDLE,  ">$folder/$cleanword.".$self->extension()) || die("cannot open file: ($folder/$word.$self->extension()) ". $!);
					print FILEHANDLE "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">";
					print FILEHANDLE "<html  xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n";

					print FILEHANDLE "<title>$word</title><link rel=stylesheet href=\"style.css\" type=\"text/css\"> </head><body>\n
					<?php include('header.inc'); ?>";
					open (FILE2,"<header.html");
					my @rawheader=<FILE2>;
					my $header=join('',@rawheader);
					close(FILE2);
					print FILEHANDLE "$header\n<div id=\"column-content\">\n<h1 class=\"firstHeading\">".$self->urldecode($word)."</h1>";
		   			print FILEHANDLE "\n$text\n";
					print FILEHANDLE "<div class=\"printfooter\"> Retrieved from &quot;<a href=\"".$uri.$word."\">".$self->urlencode($uri.$word)."</a>&quot;</div>";
		   			print FILEHANDLE "\n<?php include('footer.inc'); ?>\n</div> </body></html>";
					close (FILEHANDLE);
					#sleep 7; #don't go mad, eh?
					sleep 6;
				}
			}
		}
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mediawiki::Spider - Perl extension for flat mirror of mediawikis 

=head1 SYNOPSIS

  use Mediawiki::Spider;


=head1 DESCRIPTION

Essentially pretty simple...

=head2 EXPORT

None by default.



=head1 SEE ALSO

There were many ways to achieve this aim. This is one of them. Others (such as XSL stylesheets over mediawiki xml) would probably be cleaner.

=head1 AUTHOR

Emma Tonkin, E<lt>cselt@sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Emma Tonkin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
