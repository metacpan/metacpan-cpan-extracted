package Easy;
 
use strict; 
use vars qw($VERSION); 

$VERSION = '0.01'; 

###__________________________________________________________________________________
###
### Package Name: Easy WML
###
### Copyright (c) 2003, M. Carter Brown
###
### Contact: carter@mcarterbrown.com
###
### Functions:
###
###		new 		: Starts a new wml page
###		header	: Creates the required wml content and title name
###		print		: Prints TEXT onto the screen in wml formated form
###		img		: allows an .wbmp image to be shown and aligned if needed/wanted
###		link 		: creates a url/wml link - aligned if needed/wanted
###		textfield	: creates a field for the user to enter in text (text, password, hidden)
###		anchor	: used to POST variables to be carried over in form format
###		footer	: EOF - End of File (End of the WML page)
###
###__________________________________________________________________________________
###


###__________________________________________________________________________________
###
### Function: new
### Used for: creation of a new WML-WAP Page
### How to use:
###		my $site = new Easy->header('cardname', 'cardtitle');
###__________________________________________________________________________________
###

sub new {

	my $self = shift;
	print "Content-type: text/vnd.wap.wml\n\n";
	return $self;

}

###__________________________________________________________________________________
###
### Function: timer
### Used for: redirecting to a new WML-WAP page (i.e. used for a flash screen)
### How to use:
###		$site = Easy->timer('http://www.url_to_go_to.com', '30'); #pause for 3 seconds
###__________________________________________________________________________________
###

sub timer {

	my $self = shift;
	my ($url, $time) = @_;

	print qq~<onevent type="ontimer"><go href="$url"></go></onevent><timer value="$time"/>~;
	
	return $self;

	}

###__________________________________________________________________________________
###
### Function: header
### Used for: creating a new WML-WAP page - This function is called by the NEW function
### How to use:
###		See NEW Function
###__________________________________________________________________________________
###

sub header {

	my $self = shift;
	my ($id, $title) = @_;
	print qq~<?xml version="1.0"?>
	<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN" "http://www.wapforum.org/DTD/wml_1.1.xml">
	<wml>
	<card id="$id" title="$title">~;

	return $self;

	}

###__________________________________________________________________________________
###
### Function: print
### Used for: printing and WML formating HTML text for usage
### How to use:
###		$site = Easy->print('<br>This is my first WML Page<br>');
###__________________________________________________________________________________
###

sub print {

	my $self = shift;
	my ($format, $align) = shift;
	$format =~ s/<br>/<br\/>/g;
	
	if ($align eq "") { print qq~$format~; }
	else { print qq~<p align="$align">$format</p>~; }

	return $format;
	return $self;

	}

###__________________________________________________________________________________
###
### Function: img
### Used for: placing and formating a '.wbmp' image for WML usage
### How to use:
###		$site = Easy->img('http://www.mysite.com/image.wmbp', 'My Logo', 'center');
###__________________________________________________________________________________
###

sub img {

	my $self = shift;
	my ($link, $alt, $align) = @_;

	if ($align eq "") {
		print qq~<p><img src="$link" alt="$alt"/></p>~;
		}
	if ($align ne "") {
		print qq~<p align="$align"><img src="$link" alt="$alt"/></p>~;
		}

	return $self;

	}

###__________________________________________________________________________________
###
### Function: link
### Used for: Creating a clickable link in WML format
### How to use:
###		$site = Easy->link('http://www.url_to_go_to.com', 'Site Name');
###__________________________________________________________________________________
###

sub link {

	my $self = shift;
	my ($url, $linkname, $align) = @_;

	if ($align eq "") { 
		
		if ($linkname eq "") { print qq~<a href="$url">$url</a>~; }
		else { print qq~<a href="$url">$linkname</a>~; }

		}
	if ($align ne "") {

		if ($linkname eq "") { print qq~<p align="$align"><a href="$url">$url</a></p>~; }
		else { print qq~<p align="$align"><a href="$url">$linkname</a></p>~; }

		}

	return $self;

	}

sub textfield {

	my $self = shift;
	my ($type, $name, $size, $maxlength, $align) = @_;
	
	if ($type ne "" && $align eq "") { print qq~<input type="$type"~; } 
	if ($type ne "" && $align ne "") { print qq~<p align="$align"><input type="$type"~; } 
	if ($name ne "") { print qq~ name="$name"~; }
	if ($size ne "") { print qq~ size="$size"~; }
	if ($maxlength ne "") { print qq~ maxlength="16"~; }
	if ($align eq "") { print qq~/>~; }
	if ($align ne "") { print qq~/></p>~; }

	return $self;

	}


sub anchor {

	#TODO: A way to allow more than ONE variable to be passed through
	#################################################################

	my $self = shift;
	my ($variable, $url, $linkname, $align) = @_;

	if ($align eq "") { 
		
		if ($linkname eq "") { print qq~<anchor>$url<go href="$url" method="post"><postfield name="$variable" value="\$$variable"/></go></anchor>~; }
		else { print qq~<anchor>$linkname<go href="$url" method="post"><postfield name="$variable" value="\$$variable"/></go></anchor>~; }

		}
	if ($align ne "") {

		if ($linkname eq "") { print qq~<p align="$align"><anchor>$url<go href="$url" method="post"><postfield name="$variable" value="\$$variable"/></go></anchor></p>~; }
		else { print qq~<p align="$align"><anchor>$linkname<go href="$url" method="post"><postfield name="$variable" value="\$$variable"/></go></anchor></p>~; }

		}

	return $self;

	}

###__________________________________________________________________________________
###
### Function: footer
### Used for: Ending the WML page
### How to use:
###		$site = Easy->footer();
###__________________________________________________________________________________
###

sub footer {

	my $self = @_;
	print qq~</card></wml>~;
	return $self;

	}	


1; # for require


__END__