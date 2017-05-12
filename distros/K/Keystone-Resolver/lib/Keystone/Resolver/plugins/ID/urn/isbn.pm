# $Id: isbn.pm,v 1.2 2007-01-26 13:53:48 mike Exp $

package Keystone::Resolver::plugins::ID::urn::isbn;

use strict;
use warnings;


sub data {
    my $class = shift();
    my($openurl, $isbn) = @_;

    ### There are a number of different approaches we could take here,
    #	including:
    #	1. Resolve the ISBN to a unique page, e.g. from Amazon.
    #	2. Look up the ISBN in a catalogue service such as the Library
    #	   of Congress's Z39.50 server, and populate the referent with
    #	   the metadata obtained that way.
    #	3. Just shove the ISBN into the metadata, if it's not there
    #	   already.
    #	4. Any or all of the above, as specified either by a run-time
    #	   option or a "config" element in the resource database.
    #	Unsuprisingly, we go for option 3, at least for now.

    my $extraMetaData = {};
    $extraMetaData->{isbn} = $isbn
	if !defined $openurl->rft("isbn");

    return (undef, undef, $extraMetaData);
}


1;
