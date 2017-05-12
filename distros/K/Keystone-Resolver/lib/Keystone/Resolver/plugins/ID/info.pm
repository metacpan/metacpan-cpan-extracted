# $Id: info.pm,v 1.3 2007-06-20 13:03:40 mike Exp $

package Keystone::Resolver::plugins::ID::info;

use strict;
use warnings;


# ID plug-ins provides a single function, data().  This function is
# called with two arguments:
#
#     $openurl	The OpenURL from which the ID to be resolved is
#		drawn.  Plugins should not use this object for
#		anything more sophisticated than invoking its die()
#		and warn() methods and MUST NOT CHANGE IT.
#
#     $id	The identifier to be resolved.  The leading "scheme"
#		part of the URI is already stripped, since the plug-in
#		is scheme-specific.  For example, when the ID
#		"info:doi/10.1006/mthe.2000.0239" is encountered, the
#		"info" scheme plug-in is invoked with the $id argument
#		set to "doi/10.1006/mthe.2000.0239".
#
# The data function() must return a five-element array.  (This
# complexity is unavoidable becasue these plugins can resolve IDs in
# two very different senses, and there are a multitude of different
# error conditions):
#
#	[0]	A URI that the ID resolves to.
#
#	[1]	A "tag" to be used in labelling where the URI in
#		element 0 came from.  For example, a URI obtained by
#		resolving a DOI expressed as an "info" URI might have
#		the tag "info:doi".  This tag is used verbatim in the
#		XML document that is eventually generated to represent
#		the results of the OpenURL resolution process.  This
#		is only consulted if [0] is defined.
#
#	[2]	A reference to hash of additional key=value metadata
#		pairs to be added to the entity for which an ID is
#		being resolved.  The keys are those specified in the
#		OpenURL 1.0 standard (Z39.88), _not_ including the
#		entity-name as a prefix: so for example, using "title"
#		rather than "rft.title".
#
#	[3]	An error message.  This is only used if elements [0]
#		and [2] are both undefined, and may itself be
#		undefined to mean "nothing went wrong but the ID can't
#		be resolved for good and adequate reasons" --
#		e.g. "mailto" IDs simply cannot be resolved because
#		the concept makes no sense.
#
#	[4]	An indication of whether the error should be treated
#		as non-fatal (such as an unrecognised DOI).  If this
#		is absent or false, the error is treated as fatal
#		(such as a malformed URI).

sub data {
    my $class = shift();
    my($openurl, $address) = @_;

    # Info URIs are of the form
    #	info:<namespace>/<subaddress>
    # where namespaces include "doi", "pmid", "oclcnum", etc.  Each
    # such namespace is defined by an info URI of the form
    #	info:ofi/nam:info:<namespace>
    # and described in the OpenURL registry at
    #	http://openurl.info/registry
    # All we do in this plugin is delegate to a sub-plugin that
    # handles a particular namespace.

    # More OCLC WorldCat crap.  Its COinS objects include referent IDs
    # like "info:sici:", which is not even syntactically valid since
    # info: URIs contain a slash.  Spot these are make them harmlessly
    # no-op
    return (undef, undef, undef,
	    "syntactically invalid (OCLC?) info URI: '$address'", 1)
	if $address =~ /^[^\/]*:$/;

    my($namespace, $subaddress) = ($address =~ /(.*?)\/(.*)/);
    return (undef, undef, undef,
	    "info URI doesn't have a namespace: '$address'")
	if !defined $namespace;

    eval {
	require "Keystone/Resolver/plugins/ID/info/$namespace.pm";
    }; if ($@) {
	$openurl->warn("can't load ID info plugin '$namespace': $@");
	return (undef, undef, undef,
		"info URI namespace '$namespace' not supported ($address)");
    }

    return "Keystone::Resolver::plugins::ID::info::$namespace"->data($openurl,
								$subaddress);
}


1;
