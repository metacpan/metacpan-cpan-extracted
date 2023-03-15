package t::auto_0;

{ use 5.006; }
use warnings;
use strict;

use Test::More ();

BEGIN { Test::More::is $^H{"Lexical::SealRequireHints/test"}, undef; }

use AutoLoader ();

our $AUTOLOAD;
sub AUTOLOAD {
	$AutoLoader::AUTOLOAD = $AUTOLOAD;
	goto &AutoLoader::AUTOLOAD;
}

1;
