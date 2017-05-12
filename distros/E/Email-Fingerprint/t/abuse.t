#!/usr/bin/perl
#
# Try to break Email::Fingerprint using bad inputs, etc.

use strict;
use warnings;
use Email::Fingerprint;

use Test::More;
use Test::Exception;

my $fp = new Email::Fingerprint;

# Try checksumming... NOTHING!
dies_ok { $fp->checksum } "Checksum with no email message";

# Setters shouldn't even exist for these puppies
ok ! $fp->can('set_header'), "There should be no set_header() method at all";
ok ! $fp->can('set_body' ),  "... nor a set_body() method";
ok ! $fp->can('set_input' ), "... nor a set_intput() method";

# Try calling various private methods
dies_ok { $fp->_extract_headers } "Users shouldn't be able to call _extract_headers";
dies_ok { $fp->_extract_body }    "... nor should they be able to call _extract_body";
dies_ok { $fp->_concat }          "... nor should they be able to call _concat";

# That's all, folks!
done_testing();
