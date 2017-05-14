#!/usr/local/bin/perl

# Glenn Wood, C<glenwood@alumni.caltech.edu>.
# Copyright 1997-1998 SaveSmart, Inc.
# Released under the Perl Artistic License.
# $Header: C:/CVS/LoadWorm/loadworm.pl,v 1.1.1.1 2001/05/19 02:54:40 Glenn Wood Exp $
#
# see: http://www.york.ac.uk/~twh101/libwww/lwpcook.html
#      http://www.cs.washington.edu/homes/marclang/ParallelUA/
#				(note: the .gz file on this page is corrupt; use the individual files).
#

require 5.004;

use English;
use HTML::TreeBuilder;
use Time::Local;

use HTTP::Request;
use HTTP::Date qw(str2time);
use Carp;
use URI::Escape;
use URI::URL;
use LoadWorm;
#use LWP::Debug qw(+);
#use Devel::DProf;


	$| = 1;	# autoflush STDOUT.
	
   print "LoadWorm Version $LoadWorm::VERSION\n";

	$ua = new LWP::UserAgent;  # we create a global UserAgent object
	
	LoadWorm::GetConfiguration("loadworm.cfg");
	exit if $error;
	
	print "Autoloading all those modules.\n\n";

	$ENV{USERAGENT} = "LoadWorm" unless $ENV{USERAGENT};
	$ua->agent($ENV{USERAGENT});

	$ua->env_proxy; # initialize from environment variables
	
	$ua->proxy(['http'], $Proxy[0]);
	$ua->proxy(['https'], $Proxy[0]);
	$ua->no_proxy(@NoProxy);
	$ua->timeout($ENV{TIMEOUT});

#	&GetParseFile($TraverseURLs[0]); # this will perform all autoloading ahead of timings.
#	print "Initial setup complete.\n";

#	dbmopen %Errors, "errors", 0666;
	%Errors = ();
	
#	dbmopen %AlreadyVisited, "linkages", 0666;
	%AlreadyVisited = ();
	
	# Open a couple of report files.
   print "Opening visits file, $WD/visits.txt\n";
	open VISITS, ">$WD/visits.txt" or die "Can't open $WD/visits.txt: $!\n";
	open TIMING, ">$WD/timings.txt" or die "Can't open $WD/timings.txt: $!\n";
	

	# LET'S DO IT ! !	!
	# LET'S DO IT ! !	!
	# LET'S DO IT ! !	!
	# LET'S DO IT ! ! !
	&ListFileLinks(0, 'GET', $TraverseURLs[0], "", "");
	# WHEW, THAT'S DONE!


	$break = undef;
	print "\n\n Summary of visitations.\n";
	for $visited ( sort keys %AlreadyVisited ) {
		$visited =~ /^(...+:)/;
		if ( $break ne $1 ) {
			$break = $1;
			print "\n";
		}
		print "$AlreadyVisited{$visited} links to $visited\n";
	}
	
	# Since DB won't store hashes of arrays, we record the hash of arrays into a text file.
	open OUT, ">referers";
	if ( $Referers )
	{
		print "\n\n Referers Report.\n";
		for $visited ( sort keys %Referers )
		{
			print OUT "$visited\n";
			print "$visited\n";
			for ( sort @{ $Referers{$visited} } )
			{
				print OUT "   $_\n" if $_;
				print "   $_\n" if $_;
			}
		}
	}
	close OUT;

	print "\n\n  Summary of ignorations.\n  These URLS not requested since they matched some regex in the [Ignore] section.\n";
	for $ignore ( sort keys %AlreadyIgnored ) {
		print "$ignore\n";
		if ( $cmdline{'-ip'} ) {
			@parents = @{ $AlreadyIgnored{$ignore} };
			for $parent ( sort @parents )
			{
				print "   @{$parent}[1]\n";
			}
		}
	}

	print "\n\n  Summary of depths.\n  These URLS not traversed since they\'re too deep in the hierarchy\n";
	for $depth ( sort keys %Depths ) {
		print "$depth\n";
		if ( $cmdline{'-dp'} ) {
			@parents = @{ $Depths{$depth} };
			for $parent ( sort @parents )
			{
				print "   $parent\n" if $parent;
			}
		}
	}

 	print "\n\n Summary of errors.\n";
	for $error ( sort keys %Errors ) {
		print $error."\n".$Errors{$error}."\n";
	}

	exit;
#
# THAT'S THE MAIN FUNCTION
# THAT'S THE MAIN FUNCTION
# THAT'S THE MAIN FUNCTION






sub PrintTrace { my($dpth, $txt) = @_;
	print "  " x $dpth, $txt;
}





sub ListFileLinks { my($Depth, $GetOrPost, $Link, $BASE, $parent) = @_;	
	my(@links, $base, $html, @parents, $i);
	
	# Adjust the URL according to the BASE.
	$tmp = $Link; # This will be used to print a trace message, if $Link is changed.
	
	if ( $Link =~ /\?/ ) {
		$Link =~ /(.*)(\?.*)/;
		$Link = $1;
		$Parm = $2;
	}
	else {
		$Parm = "";
	}
	# Some SaveSmart links cause two copies of the parameter list, so we strip out one.
	if ( $Link =~ /\?/ ) {
		$Link =~ /(.*)(\?.*)/;
		$Link = $1;
		$Parm = $2;
		$Errors{$Link} = "A reference to this URL contains two '?'\nParent is $parent\n";
	};

	if ( $Link =~ /^\#/ ) {
		$AlreadyVisited{$Link} += 1;
		if ( $ENV{'VERBOSE'} ) { PrintTrace($Depth, "$Link skipped, this page refers to itself\n"); }
		return;
	}
	
	$Link = url($Link, $BASE)->abs->as_string . $Parm;
	
	# Remove any '#' label from the URL, since it never goes out anyway.
	$Link =~ s/(\#\w+)//;
# We'll need to process this label reference somehow, later, but at
#  least this prevents repeated downloads of the same page.
#	$Link .= $1;

	# Add it to the "Parents" list.
	if ( $Referers ) {
		if ( IsReferersURLs($Link) ) {
			push @{ $Referers{$Link} }, $parent;
		}
	}
	
	# Add it to the "already visited" list.
	$AlreadyLink = $Link;
	$AlreadyLink =~ s/nav=[^&]*/nav=[*]/g;
	$AlreadyVisited{$AlreadyLink} += 1;
	if ( $AlreadyVisited{$AlreadyLink} > $ENV{'RECURSE'} )
	{
		if ( $ENV{'VERBOSE'} )
		{
			if ( $AlreadyIgnored{$AlreadyLink} ) { $msg =  "ignored.\n"; }
			else { $msg = "visited.\n"; }
			PrintTrace($Depth, "$Link already ".$msg);
		}
		return;
	}

	return if &IsLimitURL($Depth, $Link, $parent);
	return if &IsIgnoreURL($Depth, $Link, $parent);

	# Limit the depth!
	if ( $Depth > $ENV{'DEPTH'} ) {
		push @{ $Depths{$Link} }, $parent;
		if ( $ENV{'VERBOSE'} ) { PrintTrace($Depth, "$Link skipped, it is too deep\n"); }
		return;
	}

	PrintTrace($Depth, $Link);
	print VISITS $Link."\n";

	$response = &GetFile($GetOrPost, $Link);
	
	unless (defined $response and &IsCheckedURL($Link, $response) )
	{
		print TIMING " failed\n";
		print " failed\n";
		return;
	}
	print "\n";
	
	# We are done here, unless it is an HTML document . . .
	unless ( ${$response}{'_headers'}{'_header'}{'content-type'}[0] eq "text/html" )
		{print TIMING "\n"; return;}
	# . . . then we must parse it, too.
	($base, $html) = &ParseFile($response);
	
	# I think that URI::URL::url() handles "func?..." wrong.  It does not belong with the $BASE, so . . .
	$base =~ s/\?.+//;

	unless ( $ENV{NOIMAGES} )
	{
		@links = @{$html->extract_links(qw(img))};
		if ( @links )
		{
         my $start = LoadWorm->GetTickCount();
			for ( @links )
			{
				&ListFileLinks($Depth+1, 'GET', @$_[0], $base, $Link);
			}
         my $finish = LoadWorm->GetTickCount();
			print TIMING "ALL_OF $Link\n$start,$finish 0\n";
		}
	}

	unless ( $ENV{NOFRAMES} )
	{
		@links = @{$html->extract_links(qw(frame))};
		if ( @links )
		{
         my $start = LoadWorm->GetTickCount();
			for ( @links )
			{
				&ListFileLinks($Depth+1, 'GET', @$_[0], $base, $Link);
			}
         my $finish = LoadWorm->GetTickCount();
			print TIMING "ALL_OF $Link\n$start,$finish 0\n";
		}
	}

	&ProcessForms($base, $html);
	
	my @anchors = @{$html->extract_links(qw(a))};
ANCHOR:	
	for my $anchor ( @anchors )
	{
		# Skip any ISMAP's in the anchor - these must be handled by <MAP>.
		# (might handle it later as a specified [INPUT] value(s))
		@map_links = @{@$anchor[1]->extract_links(qw(img))};
		for $ml ( @map_links ) {
			if ( @$ml[1]->{'ismap'} ) {
				my $tmp = url(@$anchor[0], $base)->abs->as_string;
				PrintTrace($Depth, "$tmp skipped.  It is an ISMAP.\n");
				next ANCHOR;
			}
		}
		&ListFileLinks($Depth+1, 'GET', @$anchor[0], $base, $Link);
	}
	
	
	$html->delete();
}



#
# GET FILE       	 GET FILE       	 GET FILE       	 GET FILE       	 GET FILE       												
# GET FILE       	 GET FILE       	 GET FILE       	 GET FILE          GET FILE
# GET FILE       	 GET FILE       	 GET FILE       	 GET FILE       	 GET FILE
# GET FILE       	 GET FILE       	 GET FILE       	 GET FILE       	 GET FILE
#
sub GetFile { my($GetOrPost, $thefile) = @_; my ($BASE);
	my $request;

#$thefile =~ s/^https:/http:/; # Until we can get SSLeay working on NT

	my $header = new HTTP::Headers ( 'Accept' => 'text/html' );
   my $start = LoadWorm->GetTickCount();
	print TIMING "$thefile\n$start";
#	if ( $GetOrPost eq 'POST' )
#	{
#		$thefile =~ /(.+)\?(.+)/;
#		$theurl = $1;
#		my $thecontent = $2;
#		$request = new HTTP::Request 'POST', $thefile;
#		$request->content_type('application/x-www-form-urlencoded');
#		$request->content($thecontent);
#	}
#	else
	{
		$request = new HTTP::Request 'GET', $thefile;
	}

	my $response = $ua->request($request);

	$size = $response->header('Content-Length'); #'0'; # Someday we'll figure out how to get the Content-Length.
   my $finish = LoadWorm->GetTickCount();
	print TIMING ",$finish $size\n";
	unless ( $response->is_success )
	{
		$code = $response->code;
		if ($code == &HTTP::Status::RC_MOVED_PERMANENTLY or
			 $code == &HTTP::Status::RC_MOVED_TEMPORARILY)
		{
			# Make a copy of the request and initialize it with the new URI
			my $referral = $request->clone;
			
			# And then we update the URL based on the Location:-header.
			# Some servers erroneously return a relative URL for redirects,
			# so make it absolute if it not already is.
			my $referral_uri = (URI::URL->new($response->header('Location'),
										$response->base))->abs();
			$referral->url($referral_uri);
			return GetFile($GetOrPost, $referral_uri);
		}
		else
		{
			$extra_error_info = "";
			if ( $code == &HTTP::Status::RC_METHOD_NOT_ALLOWED ) { # Method not allowed
				$extra_error_info = "Method was $GetOrPost";
			}
			$Errors{$thefile} = $response->code." ".$extra_error_info."\n".$response->as_string;
		}
		return undef
	};
	
	return $response;
}

#
#  PARSE HTML        PARSE HTML        PARSE HTML        PARSE HTML        PARSE HTML
#  PARSE HTML        PARSE HTML        PARSE HTML        PARSE HTML        PARSE HTML
#  PARSE HTML        PARSE HTML        PARSE HTML        PARSE HTML        PARSE HTML
#  PARSE HTML        PARSE HTML        PARSE HTML        PARSE HTML        PARSE HTML
#
sub ParseFile { ($response) = @_;
	
	$html = new HTML::TreeBuilder;
	$html->parse($response->content);
	
	# Determine what the BASE of this document is.
	$BASE = undef;
	# 1) The base URL can be contained in the document
	if ( $response->content_type eq 'text/html' )
	{
		# Look for the <BASE HREF='...'> tag
		my @base = @{$html->extract_links(qw(base))};
		if ( @base ) {
			$BASE = $base[0][0] if @base;
		}
	}
	# 2) There could be a Base header
	$BASE = $response->header('Base') unless $BASE;
	# 3) The URL used in the request
	unless ( $BASE )
	{
		$BASE = $response->request->url;
	}
	$html->{'_loadworm_Base'} = $BASE;
	return ($BASE, $html);
}






#
# PROCESS FORMS       PROCESS FORMS       PROCESS FORMS       PROCESS FORMS       PROCESS FORMS
# PROCESS FORMS       PROCESS FORMS       PROCESS FORMS       PROCESS FORMS       PROCESS FORMS
# PROCESS FORMS       PROCESS FORMS       PROCESS FORMS       PROCESS FORMS       PROCESS FORMS
# PROCESS FORMS       PROCESS FORMS       PROCESS FORMS       PROCESS FORMS       PROCESS FORMS
#
sub extract_tags
{
    my $self = shift;
    my %wantType; @wantType{map { lc $_ } @_} = (1) x @_;
    my $wantType = scalar(@_);
    my @links;
    $self->traverse(
		sub {
			 my($self, $start, $depth) = @_;
			 return 1 unless $start;
			 my $tag = $self->{'_tag'};
			 return 1 if $wantType && !$wantType{$tag};
			 push(@links, $self);
			 1;
		}, 'ignoretext');

	 \@links;
}


#
# Check if the give URL/Input name is in the [Input] list.
# Returns a LIST of values to be used as Inputs.
#
sub GetInputArray { my($URL, $elem) = @_;

	# First pick the explicitly stated values from [INPUT], if any.
	my $NAME = $elem->{'name'};
	$URL =~ m|/(.+)\?|;
	$form_name = $1;
	for $ky ( keys %Inputs )
	{
		$tmp = $form_name.",".$NAME;
		if ( $tmp =~ /$ky$/ )
		{
			return eval $Inputs{$ky};
		}
	}

	# Otherwise, generate a values array based on the type of INPUT.
	my @vals = ();
	if ( $elem->{'_tag'} eq '_loadworm_submit' or  # a "select" built of all submit's and image's.
	     $elem->{'_tag'} eq '_loadworm_radio' ) # a "select" built of radio checkboxes.
	{
		return @{$elem->{'_loadworm_value'}};
	}

	# If simply HTML INPUT, then use the HTML default (VALUE=).
	elsif ( $elem->{'_tag'} eq 'input' and lc $elem{'type'} ne 'radio' )	# TYPE=RADIO was handled by _loadworm_radio
	{
		$val = uri_escape($elem->{'value'});
		push @vals, $val;
	}

	# If HTML SELECT, then go through each of the selections.
	elsif ( $elem->{'_tag'} eq 'select' )
	{
		my $opt;
		my @options = @{extract_tags($elem, qw(option))};
		for $opt ( @options )
		{
			$val = $opt->{'value'};
			unless ( $val )
			{
				for $vl ( @{$opt}{'_content'} )
				{
					for ( @{$vl} )
					{
						 unless ( ref $_ )
							{$val = $_; last};
					}
				}
			}
			push @vals, $val;
		}
	}

	return @vals;
}



sub IterateInput { my($form_action, @input) = @_;
	my (@vals, $val);

	unless ( @input ) {
		chop $form_action;
		push @LinkList, $form_action;
		return;
	}

	my $elem = shift @input;

	@vals = &GetInputArray($form_action, $elem);	# Get [INPUT] values and/or _loadworm_SUBMIT and/or _loadworm_RADIO values or input.
	# Iterate according to any [Input] specification (from .cfg file).
	if ( @vals ) {
		for $val ( @vals ) {
			if ( $val eq 'NULL' ) {
				$val = '';
			}
			$val = uri_escape($val);
			if ( $elem->{'name'} ) {
				$val = $elem->{'name'}.'='.$val;
			}
			IterateInput($form_action."$val&", @input);
		}
	}
	else
	{
		print "Unknown form input tag - ".$elem->as_HTML();
	}
}


# Set up all possible values of SUBMITS and IMAGES as arrays of a virtual INPUT.
sub PreProcessSubmits { my(@inputs) = @_;
	my(@outputs, @submits, %radio_buttons) = ();

	for $input (@inputs) {
		if ( $input->{'type'} =~ /SUBMIT/i ) {
			push @submits, "$input->{'name'}=$input->{'value'}";
		}
		elsif ( $input->{'type'} =~ /IMAGE/i ) {
			push @submits, "$input->{'name'}.x=1&$input->{'name'}.y=1";
		}
		elsif ( $input->{'type'} =~ /RADIO/i ) {
			push @{$radio_buttons{$input->{'name'}}}, "$input->{'name'}=$input->{'value'}";
		}
		else
		{
			push @outputs, $input;
		}
	}
	if ( @submits ) {
		$el->{'_tag'} = '_loadworm_submit';
		@{$el->{'_loadworm_value'}} = @submits;
		push @outputs, $el;
	}
	for ( keys %radio_buttons ) {
		$elm->{'_tag'} = '_loadworm_radio';
		@{$elm->{'_loadworm_value'}} = @{$radio_buttons{$_}};
		push @outputs, $elm;
	}
	@outputs;
}


sub IterateForm { my($base, $form) = @_;

	my @inputs = @{extract_tags($form, qw(input select))};
	@LinkList = ();

	@inputs = PreProcessSubmits(@inputs);
	my $form_action = ${$form}{'action'}."?";
	# Remove any '#' label from the URL, since it never goes out anyway.
	$form_action =~ s/(\#\w+)//;

	IterateInput($form_action, @inputs);
	@LinkList;
}


sub ProcessForms { my($base, $html) = @_;
	my (@forms, $form);

	@forms = @{extract_tags($html, qw(form))};
	for $form ( @forms )
	{
		my @linklist = IterateForm($base, $form);
		for ( @linklist )
		{
			&ListFileLinks($Depth+1, $form->{'method'}, $_, $base, $html->{'_loadworm_Base'});
		}
	}
}




#sub process_forms { my($self, $flag, $depth) = @_;
#
#	return 1 unless $flag;
#	return 1 unless $self->{'_tag'} eq "form";
#
#	print "FORM -> ${$self}{'action'}\n";
#	
#	@links = @{$html->extract_links(qw(input))};
#	for ( @links ) {
#		$inpt = @$_[1];
#		print $inpt->as_HTML();
#	}
#	
#	for $fmky ( sort keys %{$self} ) {
#		if ( $fmky eq '_content' ) {
#			for $cnt ( @{$self}{$fmky} ) {
#				for ( @{$cnt} ) {
#					print ${$_{_tag}}."=".$_."\n";
#				}
#			}
#		}
#		else {
#			print $fmky."=".${$self}{$fmky}."\n";
#		}
#	}
#	0;
#}





sub PrintResponseParameters { ($response) = @_;
#	%x = %{$response};
#	%x = %{$x{'_headers'}};
#	%x = %{$x{'_header'}};
#	for ( sort keys %x ) {
#		@y = @{$x{$_}};
#		$yyy = "";
#		for $yy ( @y) { $yyy .= $yy.","; }
#		chop $yyy;
#		print "$_=".$yyy."\n";
#	}
	print ${$response}{'_headers'}{'_header'}{'content-type'}[0]."\n";
}



# Skip certain documents, well, just because!
# (but don't skip them if they are listed in $TraversURLs)
#
sub IsIgnoreURL { my($Depth, $Link, $parent) = @_;
	
	# We walk down http: links, only.
	if ( $Link !~ /^https?:\/\// )
	{
		if ( $ENV{'VERBOSE'} )
		{
			PrintTrace($Depth, "$Link skipped, it is not an http link\n");
		}
		return 1;
	}
	
	# Do not ignore if it is explicitly listed in [Traverse].
	for ( 0..$#TraverseURLs )
	{
		if ( $Link eq $TraverseURLs[$_] )
		{
			return 0;
		}
	}

	for ( 0..$#IgnoreURLs )
	{
		if ( $Link =~ /$IgnoreURLs[$_]/ )
		{
			PrintTrace($Depth, "$Link skipped by [Ignore] $IgnoreURLs[$_]\n");
			push @{@{$AlreadyIgnored{$AlreadyLink}}}, ($IgnoreURLs[$_], $parent);
			return 1;
		}
	}
	return 0;
}



# Skip certain documents if we've been the N times already!
#
sub IsLimitURL { my($Depth, $Link, $parent) = @_;
	
	for ( @main::Limits )
	{
      my ($url_match, $url_limit) = split /=/;
		if ( $Link =~ /$url_match/ )
		{
			$LimitCounts{$url_match} += 1;
			if ( $LimitCounts{$url_match} > $url_limit )
			{
				PrintTrace($Depth, "$Link skipped by [Limit] on $url_match.  This is $LimitCounts{$url_match} times.\n");
				return 1;
			}
		}
	}
	return 0;
}



# Test if this URL is one of the links traced URLs.
#
sub IsReferersURLs { my($Link) = @_;
	
	for ( 0..$#ReferersURLs )
	{
		if ( $Link =~ /$ReferersURLs[$_]/ )
		{
			return 1;
		}
	}
	return 0;
}




#
# Check the URL / content for validation, return non-zero for "do not traverse".
# This validation is done with a custom validation function specified in [Validation].
#
sub IsCheckedURL { my($Link, $response) = @_;
	my ($rtn) = 1;

	for ( keys %Validations )
	{
		if ( $Link =~ /$_/ )
		{
			$pckt = $Validations{$_};
			open TMP, ">tempfile_$$";
			print TMP $response->content;
			close TMP;
			unless ( eval "&$pckt(\'$Link\',tempfile_$$)" ) {
				print "Traversal terminated by $pckt\n";
				$rtn = 0;
			}
			unlink "tempfile_$$";
		}
	}
	return $rtn;
}


{
package LWP::UserAgent;

# We will handle redirects ourselves, instead of allowing UserAgent to go willy-nilly.
sub redirect_ok {
	return 0;
}
=pod

=cut
}

