package LWPBulkFetch;
#
#	fetch multiple pages concurrently;
#	borrowed from lwp-rget
#
use strict;
use warnings;

use threads;
use URI::URL	    qw(url);
use LWP::MediaTypes qw(media_suffix);
use HTML::Entities  ();
use LWP::UserAgent;

use vars qw($VERSION);
use vars qw($MAX_DEPTH $MAX_DOCS $PREFIX $REFERER $VERBOSE $QUIET $SLEEP $HIER $AUTH $IIS $TOLOWER $NOSPACE %KEEPEXT);

my $no_docs = 0;
my %seen = ();	   # mapping from URL => local_file
#
#	we don't write to files, we just stash in this hash
#	that we return
#
my %fetched = ();
my $ua;

# Defaults
sub new {
	my ($class, $start_url) = @_;
	$MAX_DEPTH = 5;
	$MAX_DOCS  = 50;

	$ua = new LWP::UserAgent;
	$ua->agent("LWPBulkFetch/1.00 " . $ua->agent);

	unless (defined $PREFIX) {
	    $PREFIX = url($start_url);	 # limit to URLs below this one
	    eval {
			$PREFIX->eparams(undef);
			$PREFIX->equery(undef);
	    };

	    $_ = $PREFIX->epath;
	    s|[^/]+$||;
	    $PREFIX->epath($_);
	    $PREFIX = $PREFIX->as_string;
	}

	$QUIET = 1;

	print <<"" if $VERBOSE;
START	  = $start_url
MAX_DEPTH = $MAX_DEPTH
MAX_DOCS  = $MAX_DOCS
PREFIX	  = $PREFIX

	fetch($start_url, undef, $REFERER, \%fetched);
	return \%fetched;
}

sub fetch
{
    my($url, $type, $referer, $fetched, $depth) = @_;

    # Fix http://sitename.com/../blah/blah.html to
    #	  http://sitename.com/blah/blah.html
    $url = $url->as_string if (ref($url));

	1 while ($url =~ s#(https?://[^/]+/)\.\.\/#$1#);

    # Fix backslashes (\) in URL if $IIS defined
    $url = fix_backslashes($url) if (defined $IIS);

    $url = url($url);
    $type  ||= 'a';
    # Might be the background attribute
    $type = 'img' if ($type eq 'body' || $type eq 'td');
    $depth ||= 0;

    # Print the URL before we start checking...
    my $out = (" " x $depth) . $url . " ";
    $out .= "." x (60 - length($out));
    print STDERR $out . " " if $VERBOSE;

    # Can't get mailto things
    if ($url->scheme eq 'mailto') {
		print STDERR "*skipping mailto*\n" if $VERBOSE;
		return $url->as_string;
    }

    # The $plain_url is a URL without the fragment part
    my $plain_url = $url->clone;
    $plain_url->frag(undef);

    # Check PREFIX, but not for <IMG ...> links
    if ($type ne 'img' and  $url->as_string !~ /^\Q$PREFIX/o) {
		print STDERR "*outsider*\n" if $VERBOSE;
		return $url->as_string;
    }

    # Translate URL to lowercase if $TOLOWER defined
    $plain_url = to_lower($plain_url) if (defined $TOLOWER);

    # If we already have it, then there is nothing to be done
    my $seen = $seen{$plain_url->as_string};
    if ($seen) {
		my $frag = $url->frag;
		$seen .= "#$frag" if defined($frag);
		$seen = protect_frag_spaces($seen);
		print STDERR "$seen (again)\n" if $VERBOSE;
		return $seen;
    }

    # Too much or too deep
    if ($depth > $MAX_DEPTH and $type ne 'img') {
		print STDERR "*too deep*\n" if $VERBOSE;
		return $url;
    }
    if ($no_docs > $MAX_DOCS) {
		print STDERR "*too many*\n" if $VERBOSE;
		return $url;
    }

    # Fetch document
    $no_docs++;
    sleep($SLEEP) if $SLEEP;
    my $req = HTTP::Request->new(GET => $url);
    # See: http://ftp.sunet.se/pub/NT/mirror-microsoft/kb/Q163/7/74.TXT
    $req->header ('Accept', '*/*') if (defined $IIS);  # GIF/JPG from IIS 2.0
    $req->authorization_basic(split (/:/, $AUTH)) if (defined $AUTH);
    if ($referer) {
		if ($req->url->scheme eq 'http') {
	    # RFC 2616, section 15.1.3
		    $referer = url($referer) unless ref($referer);
		    undef $referer if ($referer->scheme || '') eq 'https';
		}
		$req->referer($referer) if $referer;
    }
    my $res = $ua->request($req);

    # Check outcome
    if ($res->is_success) {
		my $doc = $res->content;
		my $ct = $res->content_type;
		my $name = find_name($res->request->url, $ct);
		print STDERR "$name\n" unless $QUIET;
		$seen{$plain_url->as_string} = $name;
		$fetched->{$plain_url->as_string} = $doc;

	# If the file is HTML, then we look for internal links
		if ($ct eq "text/html") {
	    # Save an unprosessed version of the HTML document.	 This
	    # both reserves the name used, and it also ensures that we
	    # don't loose everything if this program is killed before
	    # we finish.
		    my $base = $res->base;
no warnings;
	    # Follow and substitute links...
		    $doc =~
s/
  (
    <(img|a|body|area|frame|td)\b   # some interesting tag
    [^>]+			    # still inside tag (not strictly correct)
    \b(?:src|href|background)	    # some link attribute
    \s*=\s*			    # =
  )
    (?:				    # scope of OR-ing
	 (")([^"]*)"	|	    # value in double quotes  OR
	 (')([^']*)'	|	    # value in single quotes  OR
	    ([^\s>]+)		    # quoteless value
    )
/
  new_link($1, lc($2), $3||$5, HTML::Entities::decode($4||$6||$7),
           $base, $name, "$url", $fetched, $depth+1)
/giex;
use warnings;
	   # XXX
	   # The regular expression above is not strictly correct.
	   # It is not really possible to parse HTML with a single
	   # regular expression, but it is faster.  Tags that might
	   # confuse us include:
	   #	<a alt="href" href=link.html>
	   #	<a alt=">" href="link.html">
	   #
		}
		return $name;
    }
    else {
		print STDERR $res->code . " " . $res->message . "\n" if $VERBOSE;
		$seen{$plain_url->as_string} = $url->as_string;
		return $url->as_string;
    }
}

sub new_link
{
    my($pre, $type, $quote, $url, $base, $localbase, $referer, $fetched, $depth) = @_;

    $url = protect_frag_spaces($url);

    $url = fetch(url($url, $base)->abs, $type, $referer, $fetched, $depth);
    $url = url("file:$url", "file:$localbase")->rel
	unless $url =~ /^[.+\-\w]+:/;

    $url = unprotect_frag_spaces($url);

    return $pre . $quote . $url . $quote;
}


sub protect_frag_spaces
{
    my ($url) = @_;

    $url = $url->as_string if (ref($url));

    if ($url =~ m/^([^#]*#)(.+)$/)
    {
      my ($base, $frag) = ($1, $2);
      $frag =~ s/ /%20/g;
      $url = $base . $frag;
    }

    return $url;
}


sub unprotect_frag_spaces
{
    my ($url) = @_;

    $url = $url->as_string if (ref($url));

    if ($url =~ m/^([^#]*#)(.+)$/)
    {
      my ($base, $frag) = ($1, $2);
      $frag =~ s/%20/ /g;
      $url = $base . $frag;
    }

    return $url;
}


sub fix_backslashes
{
    my ($url) = @_;
    my ($base, $frag);

    $url = $url->as_string if (ref($url));

    if ($url =~ m/([^#]+)(#.*)/)
    {
      ($base, $frag) = ($1, $2);
    }
    else
    {
      $base = $url;
      $frag = "";
    }

    $base =~ tr/\\/\//;
    $base =~ s/%5[cC]/\//g;	# URL-encoded back slash is %5C

    return $base . $frag;
}


sub to_lower
{
    my ($url) = @_;
    my $was_object = 0;

    if (ref($url))
    {
      $url = $url->as_string;
      $was_object = 1;
    }

    if ($url =~ m/([^#]+)(#.*)/)
    {
      $url = lc($1) . $2;
    }
    else
    {
      $url = lc($url);
    }

    if ($was_object == 1)
    {
      return url($url);
    }
    else
    {
      return $url;
    }
}


sub translate_spaces
{
    my ($url) = @_;
    my ($base, $frag);

    $url = $url->as_string if (ref($url));

    if ($url =~ m/([^#]+)(#.*)/)
    {
      ($base, $frag) = ($1, $2);
    }
    else
    {
      $base = $url;
      $frag = "";
    }

    $base =~ s/^ *//;	# Remove initial spaces from base
    $base =~ s/ *$//;	# Remove trailing spaces from base

    $base =~ tr/ /_/;
    $base =~ s/%20/_/g; # URL-encoded space is %20

    return $base . $frag;
}


sub mkdirp
{
    my($directory, $mode) = @_;
    my @dirs = split(/\//, $directory);
    my $path = shift(@dirs);   # build it as we go
    my $result = 1;   # assume it will work

#    unless (-d $path) {
#		$result &&= mkdir($path, $mode);
#    }

    foreach (@dirs) {
		$path .= "/$_";
#		if ( ! -d $path) {
#		    $result &&= mkdir($path, $mode);
#		}
    }

    return $result;
}


sub find_name
{
    my($url, $type) = @_;
    #print "find_name($url, $type)\n";

    # Translate spaces in URL to underscores (_) if $NOSPACE defined
    $url = translate_spaces($url) if (defined $NOSPACE);

    # Translate URL to lowercase if $TOLOWER defined
    $url = to_lower($url) if (defined $TOLOWER);

    $url = url($url) unless ref($url);

    my $path = $url->path;

    # trim path until only the basename is left
    $path =~ s|(.*/)||;
    my $dirname = ".$1";
#    if (!$HIER) {
#	$dirname = "";
#    }
#    elsif (! -d $dirname) {
#	mkdirp($dirname, 0775);
#    }

    my $extra = "";  # something to make the name unique
    my $suffix;

    if ($KEEPEXT{lc($type)}) {
        $suffix = ($path =~ m/\.(.*)/) ? $1 : "";
    }
    else {
        $suffix = media_suffix($type);
    }

    $path =~ s|\..*||;	# trim suffix
    $path = "index" unless length $path;

    while (1) {
	# Construct a new file name
	my $file = $dirname . $path . $extra;
	$file .= ".$suffix" if $suffix;
	# Check if it is unique
	return $file unless -f $file;

	# Try something extra
	unless ($extra) {
	    $extra = "001";
	    next;
	}
	$extra++;
    }
}

1;
