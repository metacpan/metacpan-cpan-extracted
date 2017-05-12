#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..1\n"; }

use GetRc;
use strict;
use vars qw($file %data $retval);

%data = (
        'boolean' => 0,
           'error' => "This is ERROR. booboo",
);

$file = GetRc->new ('/tmp/aliases');
$file->ofs(' = ');
$retval = $file->updaterc(\%data);

print "not " if ( $retval );

print "ok 1\n";
