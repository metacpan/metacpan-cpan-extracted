package HTML::XHTML::Lite;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::XHTML::Lite ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = qw( start_page end_page getvars );

our @EXPORT = qw(
start_page end_page getvars
);

our $VERSION = '0.06';


# Preloaded methods go here.

sub start_page
{
use HTTP::Date;
use Time::Local;

$_[0]={} unless defined $_[0];

my %p=%{$_[0]};
my $page;

$p{content_type}='text/html' unless defined $p{content_type};
my $charset=(defined $p{charset} ? uc($p{charset}) : 'UTF-8');
$p{title}='Untitled Document' unless defined $p{title};
$p{dctitle}=$p{title} unless defined $p{dctitle};
$p{lang}=(defined $p{lang} ? $p{lang} : 'en');
$p{foaftitle}='FOAF' unless defined $p{foaftitle};

if ($p{feed})
{
	$p{feedtype}="application/rss+xml" unless defined $p{feedtype};
	$p{feedtitle}="RSS Feed for $p{title}" unless defined $p{feedtitle};
}

my $now=time2str(time());
my $expires=(defined $p{expires} ? time2str(iso2time($p{expires})) : $now);

unless ($p{isfile})
{
	$page.="Expires: $expires\n";
	$page.="Date: $now\n";
	$page.="Content-type: $p{content_type}; charset=$charset\n\n";
}

$page.="<?xml version=\"1.0\" encoding=\"" . lc($charset) . "\"?>\n" unless $p{noxml} || $p{nohead};
$page.="<!DOCTYPE html\n\tPUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n" unless $p{nodoctype} || $p{nohead};

$page.=<<EOT;
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$p{lang}" lang="$p{lang}">
<head>
<title>$p{title}</title>
<link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
<link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />
<meta name="DC.language" scheme="DCTERMS.RFC1766" content="$p{lang}" />
<meta name="DC.type" scheme="DCTERMS.DCMIType" content="Text" />
<meta name="DC.format" scheme="DCTERMS.IMT" content="text/html; charset=$charset" />
<meta name="DC.title" lang="$p{lang}" content="$p{dctitle}" />
EOT

$page.="<meta name=\"DC.description\" lang=\"$p{lang}\" content=\"$p{description}\" />\n" if defined $p{description};
$page.="<meta name=\"DC.creator\" content=\"$p{creator}\" />\n" if defined $p{creator};
$page.="<meta name=\"DC.identifier\" content=\"$p{identifier}\" />\n" if defined $p{identifier};
$page.="<meta name=\"DC.subject\" lang=\"$p{lang}\" content=\"$p{subject}\" />\n" if defined $p{subject};
$page.="<meta name=\"DC.rights\" content=\"$p{rights}\" />\n" if defined $p{rights};
$page.="<meta name=\"DCTERMS.created\" scheme=\"DCTERMS.W3CDTF\" content=\"$p{created}\" />\n" if defined $p{created};
$page.="<meta name=\"DCTERMS.modified\" scheme=\"DCTERMS.W3CDTF\" content=\"$p{modified}\" />\n" if defined $p{modified};
$page.="<meta name=\"DC.date\" content=\"$p{date}\" />\n" if defined $p{date};

if (defined $p{legacy} && defined $p{description} && defined $p{subject})
{
	my $kwds=$p{subject};
	$kwds=~s/;/,/g;
	$page.="<meta name=\"description\" content=\"$p{description}\" />\n";
	$page.="<meta name=\"keywords\" content=\"$kwds\" />\n";
}

$page.="<link rel=\"stylesheet\" type=\"text/css\" href=\"$p{csssrc}\" />\n" if defined $p{csssrc};
$page.="<style type=\"text/css\">$p{css}</style>\n" if defined $p{css};
$page.="<link rel=\"alternate\" type=\"$p{feedtype}\" title=\"$p{feedtitle}\" href=\"$p{feed}\" />\n" 
	if defined $p{feed};
$page.="<link rel=\"meta\" type=\"application/rdf+xml\" title=\"$p{foaftitle}\" href=\"$p{foaf}\" />\n" 
	if defined $p{foaf};
$page.=$p{extras} if defined $p{extras};
$page.="</head><body>\n";

if (defined $p{body})
{
	$page.=$p{body};
	my %footp=%p;
	$footp{string}=1;
	$page.=end_page(\%footp);
}

if ($p{string})
{
	return $page;
}
else
{
	print $page;
}

} #</start_page>

sub end_page
{
	my $page;

	$_[0]={} unless defined $_[0];

	my %p=%{$_[0]};
	$page.="\n</body></html>\n";

	if ($p{string})
	{
		return $page;
	}
	else
	{
		print $page;
	}
}

sub iso2time
{
	$_[0] =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/ or return undef;
	return timelocal($6,$5,$4,$3,$2-1,$1-1900);
}

sub getvars
{
	# A 'Lite' version of CGI.pm's param function
	# Returns a reference to a hash of arrays of
	# name/value pairs.

	my (@nvps,%vars);

	# Look after anything coming from a
	# POST form
	if (lc($ENV{REQUEST_METHOD}) eq 'post')
	{
		read(STDIN, my $postdata, $ENV{CONTENT_LENGTH});
		push(@nvps,split(/&/,$postdata));
	}

	# Pick up anything passed through the 
	# query string, either by a GET form
	# or direct by URI
	my $qs=$ENV{QUERY_STRING}; 
	$qs=~s/&/;/g;
	push(@nvps,split(/;/,$qs));
	
	foreach my $nv (@nvps)
	{
		my @a=split(/=/,$nv);
		$a[0]=~tr/+/ /;
		$a[0]=~s/%([\da-f][\da-f])/chr(hex($1))/egi;
		$a[1]="" unless defined $a[1];
		$a[1]=~tr/+/ /;
		$a[1]=~s/%([\da-f][\da-f])/chr(hex($1))/egi;
		push @{$vars{$a[0]}},$a[1];
	}
	return %vars;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HTML::XHTML::Lite - Light-weight Perl module for XHTML CGI applications

=head1 SYNOPSIS

  use HTML::XHTML::Lite;
  
     start_page({
  	title=>'my_title',
	description=>'my_description',
	...
     });

  OR pass a reference to a hash:

     start_page(\%my_page_data);
  
  
  end_page();

  my %vars=getvars();

=head1 DESCRIPTION

This module provides a light-weight alternative to the Perl built-in, CGI.pm, for
those who wish for an easy way to produce a well-formed XHTML <head></head>,
with Dublin Core metadata. A function to create a footer is provided for 
completeness and it is even possible to provide body text to return a complete 
document.  Provision is made for the inclusion of links to RSS (or other) feeds 
and FOAF data.  The 'extras' property allows for the insertion of arbitrary elements 
into the document header.

In addition to the generation of XHTML, the function getvars() is included to
populate a hash with data from the query string and POST data.  This is an
unsophisticated equivalent to CGI.pm's $q->para('xyz') functionality and does
NOT work with forms where enc="multipart/form-data" - in other words, forms that
upload files.  You will need to use CGI.pm to handle these until such time 
as that functionality is added to this module.

The aim of this module is to help produce content that is both accessible and
machine-parseable.  One of the methods of start_page(), nodoctype=>1, is provided
purely for the purpose of being able to leave out required components to check
that any validation systems being used are actually working.

=head2 FUNCTIONS

=head3 start_page()

=head4 Example

   use strict;
   use HTML::XHTML::Lite;

   start_page({
   	title=>'My Web Page',
	description=>'About My Web Page',
	creator=>'Matthew Smith',
	identifier=>'http://www.mss.cx',
	foaf=>'http://www.mss.cx/foaf.rdf',
	foaftitle=>'FOAF data',
	});

=head4 Methods

   string	Return the XHTML created as a scalar variable; the
   default behaviour is to print the XHTML to STDOUT or the
   currently selected handle.

   	my $foo=start_page({string=>1, ....., });

   isfile	Target is a file, so we don't want to create any
   headers.  This example writes to a file, without any headers.

   	open (OUT,">foo.out");
	select OUT;
	start_page({isfile=>, ....., });
	select STDOUT;
	close OUT;

   legacy	In addition to the Dublin Core dc.description and
   dc.subject, "legacy" metadata, description and keywords, are
   inserted.  The description is a straight copy of dc.description
   and keywords is dc.subject, with the semicolons (;) replaced by
   commas (,).

   	start_page({
		legacy=>1, 
		description=>$description,
		subject=>$subject,
		.....,
		});

   nodoctype	Produce a "broken" document with no Doctype declaration.
   This should only be used for test purposes.

   noxml	Do not put the <?xml ... ?> processing instruction at
   the start of the document.

   nohead	Combines nodoctype and noxml methods.

=head4 Properties

   title	The title of the page; defaults to 'Untitled Document'
   if not provided.

   dctitle	This property allows for dc.title to take a different
   value to the page title; defaults to the page title if not provided.

   identifier	Value for dc.identifier

   description	Value for dc.description

   subject	Value for dc.subject

   rights	Value for dc.rights
    
   creator	Value for dc.creator

   created	Value for dc.date.created (ISO8601 format)

   updated	Value for dc.date.updated (ISO8601 format)

   date		Value for dc.date (ISO8601 format)

   lang		Default page language (defaults to 'en')

   charset	Page character set (defaults to 'utf=8')

   content_type MIME type for the document - defaults to text/html
   		but other values, such as application/xml, may be
		used.
   
   expires	Date and time for the expiry date in the HTTP header
   		(ISO8601 format). As this module was written for CGI
		applications where data returned was seldom the same,
		this defaults to the current time, thus immediate
		expiry.

   css		CSS to be included in the document header; takes
   		prececence over csssrc styling instructions, if both
		css and csssrc are used.  For more complex situations
		where more flexibility is required, it is best to
		provide any CSS elements through the 'extras' property.

   csssrc	URI of an external CSS file

   feed		URI of an RSS (or other) feed

   feedtype	MIME type of feed - defaults to application/rss+xml

   feedtitle	Title for feed - defaults to "RSS Feed for [page title]"

   foaf		URI of a FOAF document; MIME type is provided as
   		application/rdf+xml

   foaftitle	Title for FOAF document - defaults to "FOAF"

   extras	Everything else!  If this module doesn't provide the
   		property you want, just put it in here.

   body		Providing a value for 'body' will cause an entire
   		page to be created, the <head>, body (as provided)
		and a call to end_page.

=head3 end_page()

   Close <body> and <html> elements.  Takes a hash ref [like start_page()]
   with arguments.  Currently, only 'string' is supported; returns a scalar
   if true (value is 1).

=head4 EXAMPLES

   end_page();

   - prints "\n</body></html>\n"

   end_page({string=>1});

   - returns scalar "\n</body></html\n"

=head1 DEPENDENCIES

   This module requires the following modules to be installed:

   HTTP::Date
   Time::Local

   These are used to create time/date strings for the HTTP headers.


=head1 TO DO

   * Inclusion of dc.accessibility, when more mature
   * Links to EARL assertions about the document
   * You tell me...

=head1 APPLICATION EXAMPLE

#!/usr/bin/perl

# Programme to create XHTML template
# through command line interaction.

use strict;
use warnings;
use HTML::XHTML::Lite;

my @tnow=localtime(time());
my $yearnow=1900+$tnow[5];
my $datenow="$yearnow-$tnow[4]-$tnow[3]";

print "C R E A T E   X H T M L   D O C U M E N T\n";
print "-----------------------------------------\n\n";

my $myname=ui('Your name','Fred Bloggs');
my $myname_=$myname;
$myname_=~s/\s/_/g; $myname_=~s/\.//g;
my $defrights="(C) Copyright $yearnow $myname";
my $filename=ui('File name',"${datenow}_${myname_}.html");
my $title=ui('dc:title','Untitled');
my $description=ui('dc:description','My Document');
my $subject=ui('dc:subject','');
my $creator=ui('dc:creator',$myname);
my $created=ui('dc:date.created',$datenow);
my $updated=ui('dc:date.updated',$datenow);
my $rights=ui('dc:rights',$defrights);
my $identifier=ui('dc:identifier',"file://$filename");
my $stylesheet=ui('Stylesheet source URI','default.css');

open (OUT,">$filename") or die "Can't write to $filename: $!";
select OUT;
start_page({
	isfile=>1,
	title=>$title, description=>$description, subject=>$subject,
	creator=>$creator, created=>$created, updated=>$updated,
	rights=>$rights, identifier=>$identifier,
	csssrc=>$stylesheet,
	body=>"<h1>$title</h1>",
	});
select STDOUT;
close OUT;

sub ui
{
	my ($prompt,$def)=@_;
	$prompt.=" [$def]" if defined $def;
	$prompt.=':';
	print $prompt;
	$_=<STDIN>;
	chomp;
	if (defined $def) { return $_ ? $_ : $def; }
	else { return $_; }
}


=head1 SEE ALSO

A web page for this module may be found here:
http://www.mss.cx/xhtmllite/

The alternative:	man CGI.pm
Dublin Core Metadata:	http://www.dublincore.org
XHTML Specification:	http://www.w3.org/TR/xhtml1/

=head1 AUTHOR

Matthew Smith, smiffy@cpan.org

Matthew welcomes feedback and suggestions regarding this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Matthew Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
