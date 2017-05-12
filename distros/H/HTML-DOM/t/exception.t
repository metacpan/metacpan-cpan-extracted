#!/usr/bin/perl -T

# This tests the DOMException and EventException interfaces, which are both
# implemented by HTML::DOM::Exception

use strict; use warnings;

use Test::More tests => 22;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::Exception', ':all'; }

# -------------------------#
# Tests 2-17: check constants

{
	my $x;

	for (qw/ INDEX_SIZE_ERR DOMSTRING_SIZE_ERR HIERARCHY_REQUEST_ERR
	        WRONG_DOCUMENT_ERR INVALID_CHARACTER_ERR
	       NO_DATA_ALLOWED_ERR NO_MODIFICATION_ALLOWED_ERR
	     NOT_FOUND_ERR NOT_SUPPORTED_ERR INUSE_ATTRIBUTE_ERR
	  INVALID_STATE_ERR SYNTAX_ERR INVALID_MODIFICATION_ERR
	NAMESPACE_ERR INVALID_ACCESS_ERR /) {
		eval "is $_, " . ++$x . ", '$_'";
	}
	is UNSPECIFIED_EVENT_TYPE_ERR, 0, 'UNSPECIFIED_EVENT_TYPE_ERR';
}

# --------------------------------------- #
# Tests 18-22: constructor and object interface #

{
	my $x = new HTML::DOM::Exception NOT_SUPPORTED_ERR,
		'Seems we lack this feature';
	isa_ok $x, 'HTML::DOM::Exception', 'the new exception object';
	is "$x", "Seems we lack this feature\n",
		'string overloading that adds a newline';
	is 0+$x, NOT_SUPPORTED_ERR, 'numeric overloading';
	is $x->code, NOT_SUPPORTED_ERR, 'code';
	$x = new HTML::DOM::Exception NOT_SUPPORTED_ERR,
		qq'Another exceptional object\n';
	is $x, "Another exceptional object\n",
	    'string overloading when there is already a trailing newline';
}
