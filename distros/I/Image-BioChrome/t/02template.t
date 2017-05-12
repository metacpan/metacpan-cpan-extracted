#!/usr/bin/perl -w

# t/t9.t
#
# Test script for the BioChrome Template Plugin

use strict;

use lib qw(. ./t ./lib ../lib ./blib/lib ../blib/lib);

eval "use Template";
if ($@) {
die "SAM:$@";
	print "1..0 # skipped: Template module not installed\n";
	exit;
}


eval "use Template::Test";

my $dir = -d 't' ? 't/gif' : 'gif';

test_expect( \*DATA, undef, { dir => $dir, file => $dir . '/simple.gif'}  );

__END__
-- test --
[% USE bio = BioChrome( file );
bio.alphas(['ff0000','ffffff']);
bio.write_file( "$dir/output3.gif" );
%]

-- expect --


-- test --
[% TRY;
	USE bio = BioChrome('foobar.gif');
   CATCH biochrome -%]
A biochrome error occurred: [% error.info;
   END;
   %]

-- expect --

A biochrome error occurred: File not found: foobar.gif

-- test --
[% USE bio = BioChrome( file );
bio.alphas(['ff0000','ffffff']);
TRY;
	bio.write_file( "$dir/output3.gif/output3.gif" );
CATCH biochrome;
-%]
A biochrome error occurred: [% error.info %]
[%
END
%]

-- expect --

A biochrome error occurred: Failed to make directory
