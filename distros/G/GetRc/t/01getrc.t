#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..1\n"; }

use GetRc;
use strict;
use vars qw($file %aliases $retval);

if ( -e "/etc/aliases" ){
  $file = GetRc->new ('/etc/aliases');
  $file->ifs('\s*:\s*');
  $file->multivalues(0);
  $retval = $file->getrc(\%aliases);

  print "not " if ( $retval );
} else {
  print "Where is /etc/aliases file ??\n";
}

print "ok 1\n";
