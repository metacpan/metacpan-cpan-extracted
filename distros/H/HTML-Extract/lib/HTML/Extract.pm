package HTML::Extract;

use 5.008006;
use strict;
use utf8;
use warnings;
use HTML::TreeBuilder;
use HTML::Element;
use LWP::UserAgent;
use HTML::Parser;
use Encode;
# use encoding 'utf8';

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::Extract ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( 
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.25';


# Preloaded methods go here.


sub new {
        my $package = shift;
        my $self= {
           _uri=> undef,
           _raw=> undef,
           _remnant=> undef,
           _tagclass=> undef,
           _atagname=> undef,
           _tagid=> undef,
                 };
        #return bless({}, $package);
        return bless ($self,$package);
}


sub settagclass {
        my ( $self, $tagclass ) = @_;
        $self->{_tagclass} = $tagclass if defined($tagclass);
        return $self->{_tagclass};
}

sub settagname {
        my ( $self, $tagname ) = @_;
        $self->{_atagname} = $tagname if defined($tagname);
        return $self->{_atagname};
}

sub settagid {
        my ( $self, $tagid ) = @_;
        $self->{_tagid} = $tagid if defined($tagid);
        return $self->{_tagid};
}

sub seturi {
        my ( $self, $uri ) = @_;
        $self->{_uri} = $uri if defined($uri);
        return $self->{_uri};
}

sub gethtml {
	#my ( $self, $uri, $tagclass, $tagname, $tagid) = @_;
        my ( $self, $uri, $command, $areturntype) = @_;
		my $commandname;
		my $commandvalue;

		$areturntype=~/\=(.*)$/ if defined($areturntype);
		if($1){
		 	$areturntype=$1;	
		}
		my $toreturn="HTML";
		$toreturn=$areturntype if defined($areturntype);
		
		if(!$command eq ""){
			($commandname,$commandvalue)=split(/=/,$command);
		} else {
			$commandname="tagname";
			$commandvalue="html";
		}
		my $tagclass;
	   	my $tagname;
		my $tagid;
		if($commandname eq "tagclass"){
			$tagclass=$commandvalue;
		} elsif ($commandname eq "tagname") {
			$tagname=$commandvalue;
		} elsif($commandname eq "tagid"){
			$tagid=$commandvalue;
		}
		
		$self->seturi($uri) if defined($uri);	
		$self->settagclass($tagclass) if defined($tagclass);	
		$self->settagname($tagname) if defined($tagname);	
		$self->settagid($tagid) if defined($tagid);	

		my $browser=LWP::UserAgent->new(
			'Accept-Charset' => 'utf-8',
		);
		# my $tf=HTML::TagFilter->new(allow=>{});
		my $tree = HTML::TreeBuilder->new();
		my $content = $browser->get($uri);
		return "<b>Couldn't get $uri</b>\n" unless defined $content;
		# Problem; the system does not know that content has UTF8 flavour
		# so tell it that it does...
		my $content2 = $content->content;
		Encode::_utf8_on($content2);
		#	$tree->parse($content->content)|| die "Bah! $!\n";
		$tree->parse($content2)|| die "Bah! $!\n";
		$tree->eof();
		my @candidates;

		if($tagclass){
			@candidates = $tree->look_down ("class", qr/$tagclass/);
		} elsif ($tagname){
			@candidates = $tree->look_down("_tag",qr/$tagname/);
		} elsif ($tagid){
			@candidates = $tree->look_down("id",qr/$tagid/);

		}
		if($#candidates>-1){	
			if($toreturn eq "text" || $toreturn eq "txt"){
				return $candidates[0]->as_text();
			} else {
				my $text=$candidates[0]->as_HTML();
				return $text;
			}
		} else{
			return "<b>No candidates found</b>";
		}
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HTML::Extract - Perl extension for getting text and HTML snippets out of HTML pages in general. 

=head1 SYNOPSIS

  use HTML::Extract;
  my $extractor=new HTML::Extract;
  # return a text version of the content
  print $extractor->gethtml(http://uri/,tagname=body,returntype=text);

  
=head1 DESCRIPTION

This is a pretty simple little Perl module for getting text out of HTML pages. It's really designed so that you can call it in anything where you would otherwise be looking for a way of stripping part of web pages away (for example, if you are extracting some pieces of text with the intent of placing it elsewhere). It also comes with a little demonstration program that shows how it can be wrapped as a command line program... 

=head2 EXPORT

None.



=head1 SEE ALSO

Obviously this makes use of quite a few other modules to do what it does; HTML::Element, HTML::TreeBuilder, HTML::TagFilter, LWP::UserAgent, LWP::Simple.  

=head1 AUTHOR

Emma Tonkin, E<lt> cselt@users.sourceforge.net E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Emma Tonkin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
