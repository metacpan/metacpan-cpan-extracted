package Mediawiki::Spider;

use 5.008006;
use strict;
use warnings;
use LWP::UserAgent;
#use Data::Dumper;
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
           _sortedwikiindex=> undef,
			_extension=>"html",
                 };
        #return bless({}, $package);
        return bless ($self,$package);
}

sub urldecode {

      my ($self,$str) = @_;
      $str =~ s/%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

      return $str;
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

sub sortedwikiindex{
       my ( $self, %sortedwikiindex) = @_;
       %{$self->{_sortedwikiindex}} = %sortedwikiindex if %sortedwikiindex ;
       if( defined(%{$self->{_sortedwikiindex}})) {
                   return %{$self->{_sortedwikiindex}};
           };
}

sub wikiindex{
	# wikiindex; a hash of hashes?
       my ( $self, %wikiindex) = @_;
       %{$self->{_wikiindex}} = %wikiindex if %wikiindex ;
       if( defined(%{$self->{_wikiindex}})) {
                   return %{$self->{_wikiindex}};
           };
}


sub wikiwords{
       my ( $self, @wikiwords) = @_;
       @{$self->{_wikiwords}} = @wikiwords if @wikiwords ;
       if( defined(@{$self->{_wikiwords}})) {
                   return @{$self->{_wikiwords}};
           };
}

sub buildmenu{
	my ($self,%addedhash)=@_;
	my %wikiindex=$self->wikiindex();
	my %inversion;
	for my $key (keys %wikiindex)  {
			for my $key2( keys %{$wikiindex{$key}}){
					if($key2 ne "" && $key ne ""){
					$inversion{$key2}->{$key}=1;
					}
			}
	}
	# print "Inversion: ".Data::Dumper->Dump([%inversion]);
	$self->sortedwikiindex(%inversion);
	return %inversion;
}

sub makepretty{
	my($self,$string)=@_;
	$string=~s/\_/\ /g;
	return $string;
}

sub printmenu{
	# also get it to put %extras in -- extras should be a hash similar to %inverted
	my ($self, $page, $extratitle,@extras)=@_;
	my %sortedindex=$self->sortedwikiindex();
    open (FILE2,"<header.html");
    my @rawheader=<FILE2>;
    my $header=join('',@rawheader);
    close(FILE2);

    open(FILEHANDLE, ">$page") || die("($page): cannot open file: ". $!);
	print FILEHANDLE "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">";
	print FILEHANDLE "<html  xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n";
	print FILEHANDLE "<title>Index</title>\n<link rel=stylesheet href=\"style.css\" type=\"text/css\"> \n</head>\n<body>\n";
	print FILEHANDLE "<?php include('header.inc');?>";
	print FILEHANDLE "$header\n";
	print FILEHANDLE "<div id=\"column-content\">";
	my $incremental=0;
	for my $key (sort keys %sortedindex) {
		$incremental++;
		# put in categories you wish to exclude
		if($key=~/Exclude/){
			next;
		} elsif($key=~/^Category$/){
			next;
		}
		my $keytoshow=$key;
		$keytoshow=~s/Category\://g;
		$keytoshow=$self->makepretty($keytoshow);
		print FILEHANDLE "\n<div id=\"inc$incremental\"><h3>$keytoshow</h3>\n <p id=\"incs$incremental\">";
		for my $key2 (sort keys %{$sortedindex{$key}}){
			my $key2toshow=$key2;
			if($key2=~/rint_All/){
				next;
			} elsif($key2=~/_Context/){
				next;
			}
			$key2toshow=$self->makepretty($key2toshow);
			print FILEHANDLE "<a href=\"".$key2.".".$self->extension()."\">$key2toshow</a>\n";
			print FILEHANDLE "<br/>\n";
		}
		print FILEHANDLE "</p></div>\n";
			
	}
	if($extratitle && $#extras>-1){
		$incremental++;
		print FILEHANDLE "\n<div id=\"inc$incremental\"><h3>$extratitle</h3>\n<p id=\"incs$incremental\">";
		foreach my $key3 (@extras){
			print FILEHANDLE "\n<a href=\"".$key3.".".$self->extension()."\">".$self->makepretty($self->urldecode($key3))."</a>\n";
			print FILEHANDLE "<br/>\n";
		}
		print FILEHANDLE "\n</p></div>\n";
	}
	print FILEHANDLE "\n</div>\n<?php include('footer.inc'); ?></body></html>";
	close(FILEHANDLE);	
	return;
}

sub getwikiwords {
	my ($self,$uri)=@_;
	$self->seturi($uri) if defined($uri);
	my @wikiwords;
	my $browser=LWP::UserAgent->new();
	my $content = $browser->get($uri);
	if($content->{_rc} eq "200"){
		my $theuri= $content->{_request}->{_uri};
		$theuri=~/^(.*)\//;
		$theuri=$1."/";
		$self->seturi($theuri);
		#print "URI: $theuri";
	 	$content=$browser->get($theuri."Special:Allpages");			
		my @lines=split(/\/Special:Allpages\//,$content->{_content});
		my $currentwikiword="";
		my @specialpages;
		foreach my $line (@lines){
			if ($line=~/^([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)/){
				if($1 eq $currentwikiword){
					push(@specialpages,$theuri."Special:Allpages\/".$currentwikiword);
				} else {
					$currentwikiword=$1;
					
				}
			}
		#}
		}
		
		if($#specialpages<0){
			push(@specialpages,$theuri."Special:Allpages\/");
		}
		
		foreach my $specialpage (@specialpages){
	 		$content=$browser->get($specialpage);			
			#my $newcontent=split(/title\=\"Special\:Allpages\"\>All\ pages/,$content);
			my @newcontent;
			@newcontent=split(/Special\:Allpages\"\>All\ pages/,$content->{_content});
			@newcontent=split(/\<div\ class=\"printfooter\"\>/,$newcontent[1]);
			@lines=split(/\<a\ href\=/,$newcontent[0]);
			foreach my $line (@lines){
				#$line=~/title=\"([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)\"/;
				# print "$line\n\n";
				$line=~/\"\/index\/([^\"^\ *]+)\"/;
				if($1){
					push(@wikiwords,$1);
					#	print "Wikiword: ".$1."\n";
				}
			}
		}

		if($#wikiwords<0){
			return -2;
		} else {
			$self->wikiwords(@wikiwords);
			return @wikiwords;
		}
		
		
	} else {	
		#print "Page does not exist";
		return -1;
	}
}

# TODO: clean up this code!!

sub do_wikisuck {
	# Berlin schoenefeld airport, 31st Dec 2006 18.36pm
	# Recursive wiki suck function; keep going til @categories eq wikiwords 
    my ( $self, $folder,$makecategories,@categories) = @_;
	my $extractor=new HTML::Extract();
	my @wikiwords;
	my %wikiindex;
	@wikiwords=$self->wikiwords();
	%wikiindex=$self->wikiindex();
	#print "Wikiwords".Data::Dumper->Dump([@wikiwords])."\n";
	#print "Wikiindex".Data::Dumper->Dump([%wikiindex])."\n";
	
	# TODO: if is redirect then DO NOT SAVE IT!!
	my $uri=$self->seturi();
	$uri=~/(.*)\/(.*)\//;
	my $uriextension=$2;
	my %is_wikiword = ();
	for (@wikiwords)  { $is_wikiword{$_} = 1 }  
	# have to compare @categories and @wikiwords
	my $temptest;
	foreach my $word (@categories){
		$temptest=$word;
		$temptest=~s/\:/\-/g;
		if($is_wikiword{$word} || $is_wikiword{$temptest}){ # we already did this word (we got the wikiwords from special::allpages)!
			print "Ignoring $word (already done)\n";
				#	return;	
		} elsif($word=~/http\:\/\/(.*)/){ # no sucking the whole interweb, please!
			print "Ignoring $word (inappropriate) \n";
		} elsif($word=~/(.*)\.(\w\w|\w\w\w)\/(.*)/){ # thingy.wossname.ac.uk/something?
			print "Ignoring $word (inappropriate) \n";
		} elsif($word=~/Mediawiki\:/){
		} elsif($word=~/Special\:/){
		} else {
			sleep 3;
			print "Looking at $word (do)\n";
			push(@wikiwords,$word); # is this the right way round?
			$is_wikiword{$word}=1;
			$self->wikiwords(@wikiwords); # add that back to the collective 'dealt with' list
			my $text=$extractor->gethtml($uri.$word,"tagid=content");
			$text=~s/\<table class="wikitable"(.*?)\<\/table\>//;
			#$text=~s/<div class="printfooter"(.*?)\<\/div\>//;
			my @rawcategories;
			if($self->extension()!=""){
				my $ext=$self->extension();
				$text=~s/\"\/$uriextension\/([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)/\"$1\.$ext/g;
				@rawcategories=split(/href=\"([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)\.$ext/,$text);
			} else {
				$text=~s/\"\/$uriextension\/([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)/\"$1\.html/g;
				@rawcategories=split(/href=\"([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)\.html/,$text);
			}
			if(!$#rawcategories<1){
			foreach my $category (@rawcategories) {
				# in page $word we found categories @rawcategories
				$category=~/(^[0-9A-Za-z\-\_\:\%\&\.\,\;\+\#]+)$/;
				if(!$1 eq ""){
					#print "Considering category $1\n";
					push(@categories,$1);
					my $topush=$1;
					if($topush=~/Category/ && !$word=~/Category/){
						print "Pushing $topush\n";
						$wikiindex{$word}->{$topush}=1;
						$self->wikiindex(%wikiindex);
					}	
				} # check this bit for safety - it may well be possible to craft dangerous wikiwords...
				}
				$text=~s/href=\"Category:([0-9A-z\-\_\%\&\.\,\;\+\#]+)/href=\"Category-$1/g;
				$word=~s/\:/\-/g;

				# if page content contains noinclude tag, don't include it
				if($text=~/Category:Exclude/){
					print "Not printing $word (excluded)\n";
				} else {
					$text=~s/\[<a href=(.*?)\W+>edit<\/a>\]//g;
					#$text=~s/\<table class="wikitable"(.*?)\<\/table\>//;
					$text=~s/<div id="catlinks"(.*?)\<\/div\>//;
					$text=~s/<div id="jump-to-nav">(.*?)\<\/div\>//;
					open(FILEHANDLE, ">$folder/".$self->urldecode($word).".".$self->extension()) || die("($word): cannot open file: ". $!);
                    open (FILE2,"<header.html");
                    my @rawheader=<FILE2>;
					my $header=join('',@rawheader);
                    close(FILE2);
					print FILEHANDLE "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">";

					print FILEHANDLE "<html xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n<title>$word</title>\n<link rel=stylesheet href=\"style.css\" type=\"text/css\"/>\n </head>\n<body>\n";
					print FILEHANDLE "\n<?php include('header.inc'); ?>\n";
					print FILEHANDLE "$header\n$text\n";
					print FILEHANDLE "\n<?php include('footer.inc'); ?>\n";
					print FILEHANDLE "</body></html>";	#sleep 7; #don't go mad if not using this on own site!
					close(FILEHANDLE);
				}
			}
		}
	}
    my %saw;
    undef %saw;
    my @out = grep(!$saw{$_}++, @categories);
    @categories=@out;

	my @finalcategories;
	%is_wikiword= ();
	for (@wikiwords)  { $is_wikiword{$_} = 1 }  
	for(@categories){
		if(!$is_wikiword{$_}){
			push(@finalcategories,$_);
		}
	}
	# have to compare @categories and @wikiwords
	if($#finalcategories>0){
		# $self->do_wikisuck($folder,$makecategories,@finalcategories);
		# no need to actually recurse for this task, it appears... but nonetheless
		print "Left to do:".Data::Dumper->Dump([@finalcategories])."\n";
		print Data::Dumper->Dump([%wikiindex]);
	}
}

sub makeflatpages{
	## make this thing recursive tomorrow...	
       my ( $self, $folder,$makecategories) = @_;
	   my @wikiwords=$self->wikiwords();
	   # print "Wikiwords".Data::Dumper->Dump([@wikiwords])."\n";
	   my $extractor=new HTML::Extract();
	   my $uri=$self->seturi();
	   $uri=~/(.*)\/(.*)\//;
	   my $uriextension=$2;
	   my @categories;
	   my %wikiindex;
	   # @wikiwords=('Technical_Frameworks_Context');
	   foreach my $word (@wikiwords){
		   if($word=~/http\:\/\/(.*)/){ # no sucking the whole interweb, please!
			   	print "Looking at $word (ignore) \n";
		   }else { 	# get page, collect categories...
			   sleep 3;
			   	print "Looking at $word (get page) \n";
		   		my $text=$extractor->gethtml($uri.$word,"tagid=content");
				if($text=~/\<div\ id=\"contentSub\">\(Redirected from/){
					print "Don't want this word (Is redirect)\n";
					next;
				}
				#$text=~s/\<table class="wikitable"(.*?)\<\/table\>//;
				#$text=~s/<div id="catlinks"(.*?)\<\/div\>//;
				#$text=~s/<div id="jump-to-nav">(.*?)\<\/div\>//;
				$text=~s/\<table class="wikitable"(.*?)\<\/table\>//;
				$text=~s/\"\/$uriextension\/([0-9A-z\-\_\:\%\&\.\,\;\+\#]+)/\"$1\.html/g;
				my @rawcategories=split(/href=\"([0-9A-z\-\_\:\%\&\.\,\;\+]+)\.html\"/,$text);
				# this buggers up when there are 0 categories.
				if($#rawcategories<1){
					print "Raw categories: ".$#rawcategories."\n";
				} else {
				# my @rawcategories=split(/href=\"\/$uriextension\/(.*)\"/,$text);
				# print Data::Dumper->Dump([@rawcategories]);
				foreach my $category (@rawcategories) {
						$category=~/(^[0-9A-Za-z\-\_\:\%\&\.\,\;\+\#]+)$/;
						if(!$1 eq ""){
							 #print "Category is $1\n";
						push(@categories,$1);
						my $topush=$1;
						if($topush=~/Category/ ){		
							#print "Pushing $topush\n";
							$wikiindex{$word}->{$topush}=1;
							}
					
						}
					}
				} 
				if($text =~ /Category:Exclude/){
					print "Not printing $word (excluded)\n";
				} else {
					# Do not have category: files... : in files is bad
					$text=~s/href=\"Category:([0-9A-z\-\_\%\&\.\,\;\+\#]+)/href=\"Category-$1/g;
					# squelch the '[edit]' links
					$text=~s/\[<a href=(.*?)\W+>edit<\/a>\]//g;
					$text=~s/<div id="catlinks"(.*?)\<\/div\>//;
					$text=~s/<div id="jump-to-nav">(.*?)\<\/div\>//;
					open(FILEHANDLE, ">$folder/$word.".$self->extension()) || die("cannot open file: ". $!);
                    open (FILE2,"<header.html");
                    my @rawheader=<FILE2>;
					my $header=join('',@rawheader);
                    close(FILE2);
					#print FILEHANDLE "<meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />";
					print FILEHANDLE "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">";
					print FILEHANDLE "<html  xmlns=\"http://www.w3.org/1999/xhtml\"><head><title>$word</title><link rel=stylesheet href=\"style.css\" type=\"text/css\"> </head><body>";
					print FILEHANDLE "\n<?php include('header.inc'); ?>\n";
		   			print FILEHANDLE "$header\n$text";
					print FILEHANDLE "\n<?php include('footer.inc'); ?>\n";
		   			print FILEHANDLE "</body></html>";
					close (FILEHANDLE);
					#sleep 7; #don't go mad, eh?
				}
			}
			 my %saw;
			 undef %saw;
		     my @out = grep(!$saw{$_}++, @categories);
			@categories=@out;	 
			# print Data::Dumper->Dump([@categories])."\n";
		}
		print Data::Dumper->Dump([%wikiindex]);
		$self->wikiindex(%wikiindex);
		if($makecategories){
			$self->do_wikisuck($folder,$makecategories,@categories);
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
