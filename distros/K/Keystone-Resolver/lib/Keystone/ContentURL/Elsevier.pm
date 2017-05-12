# $Id: Elsevier.pm,v 1.4 2007-05-24 17:04:09 mike Exp $

package Keystone::ContentURL::Elsevier;

use strict;
use URI::Escape qw(uri_escape_utf8);
use Digest::MD5;


# See ../../doc/providers/elsevier/GIS40R4P.pdf
# for a description of the process going on here.
#
# To use this module, create a Keystone::ContentURL::Elsevier object,
# passing in the Origin, Salt Version, Salt and Base-URL, that you've
# been allocated.  If the Base-URL is omitted, the standard one is
# used.  Thereafter, you can repeatedly call its url() method, passing
# in whatever metadata you have from the list of relevant elements.
# This will either return a URL for the article, or throw an exception
# (a string containing an error message)

sub new {
    my $class = shift();
    my($origin, $saltVersion, $salt, $baseURL) = @_;

    $baseURL = "http://www.sciencedirect.com/science" if !defined $baseURL;
    return bless {
	origin => $origin,
	saltVersion => $saltVersion,
	salt => $salt,
	baseURL => $baseURL,
    }, $class;
}

sub url {
    my $this = shift();
    foreach my $param (@_) {
	$param = uri_escape_utf8($param) if defined $param;
    }
    my($pii, $issn, $volume, $issue, $firstPage, $lastPage, $initial,
       $surname, $year) = @_;

    my($type, $key);
    if (defined $pii) {
	$type = "pii";		# "publisher identified item"
	$key = $pii;
	$key =~ s/[^a-zA-Z0-9]//;
    } elsif (defined $issn && defined $volume && defined $firstPage) {
	$issn =~ s/-//;
	$type = "vol";		# Volume key (a.k.a. IVIP key)
	$key = "$issn#$volume#$firstPage";
	$key .= "#$issue" if defined $issue;
    } elsif (defined $surname && defined $year && defined $firstPage) {
	$type = "ref";		# Reference key
	$key = "$surname#$year#$firstPage";
	$key .= "#" if defined $lastPage || defined $initial;
	$key .= "$lastPage" if defined $lastPage;
	$key .= "#$initial" if defined $initial;
    } else {
	die "not enough metadata supplied for PII, _volkey or _refkey";
    }

    # MD5 sum must be calculated on the _un_encoded values
    my $query = ("_ob=GatewayURL&" .
		 "_origin=" . $this->{origin} .
		 "&_method=citationSearch" .
		 "&_${type}key=" . $key .
		 "&_version=" . $this->{saltVersion});
    my $md5 = Digest::MD5::md5_hex($query . $this->{salt});

    # Actual URL must use encoded values (particularly, "%23" for "#")
    ### Does the Elsevier gateway expect us to encode UTF8 or Latin1?
       $query = ("_ob=GatewayURL&" .
		 "_origin=" . uri_escape_utf8($this->{origin}) .
		 "&_method=citationSearch" .
		 "&_${type}key=" . uri_escape_utf8($key) .
		 "&_version=" . $this->{saltVersion});

    return $this->{baseURL} . "?$query&md5=$md5";
}


1;
