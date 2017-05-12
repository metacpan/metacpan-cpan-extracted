package GetWeb::Util;

use GetWeb::File;
use URI::URL;

use strict;

sub getRefTag
{
    "*** References from this document ***\n";
}

sub getFormRefTag
{
    "*** Form section (ignore) ***\n";
}

sub untaintURL
{
    my $url = shift;

    $url =~ /\\/ and die "illegal url:  $url";
    $url =~ /^file/ and die "file does not pass taint-check";
    $url =~ /(.+)/;
    $1;
}

sub safeRequest
{
    my $fullString = shift;
    my $cwd = shift;
    my $method = shift || 'GET';

    $fullString =~ s/^\s+//;

    if ($cwd eq '')
    {
	my $config = MailBot::Config::current;
	$cwd = $config -> getPubDir;
    }

    my $url;
    if ($fullString =~ s%^file:/*%%)
    {
	$url = newlocal GetWeb::File($fullString);
    }
    else
    {
	$fullString = untaintURL($fullString);
	$url = new URI::URL($fullString);
	defined $url or
	    die "could not parse url $fullString";
    }

    my $scheme = $url -> scheme;
    if ($scheme eq 'news' or
	$scheme eq 'mailto')
    {
	die "UNAVAILABLE: $scheme is not supported\n";
    }

    my $request = new HTTP::Request($method,$url);
    $scheme eq 'ftp' and
	$request -> header('Accept','text/html');  # get dir list as HTML
    $request;
}

1;
