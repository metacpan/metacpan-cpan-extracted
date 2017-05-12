# $Id: APP.pm,v 1.2 2007-01-26 13:53:48 mike Exp $

package Keystone::Resolver::plugins::Service::APP;

use strict;
use warnings;


# This plug-in demonstrates a semi-complex access method for a service
# that does not provide uniform access.  The journal _Acta
# Palaeontologica Polonica_ is archived on its own web-site, but only
# from volume 42 onwards.  From volume 47, the full text is provided
# rather than just abstracts, and the URLs are different at that
# point, too.

sub uri {
    my $class = shift();
    my($openurl) = @_;

    my($volume, $issue, $spage, $aulast)
	= map { $openurl->rft($_) } qw(volume issue spage aulast);

    if ($volume < 42) {
	return (undef, "this service does not support volumes prior to 42");
    } elsif ($volume >= 47) {
	# New form, with full-text PDFs
	return sprintf("http://app.pan.pl/acta%d/app%d-%03d.pdf",
		       $volume, $volume, $spage);
    }

    # Old form: abstracts only.  Author name is used as locator within
    # the page, which is surely fragile to character-encoding issues.
    return "http://app.pan.pl/acta$volume-$issue.htm#$aulast";
}


1;
