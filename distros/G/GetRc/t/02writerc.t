#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..1\n"; }

use GetRc;
use strict;
use vars qw($file %data $retval);

%data = (
  'personal-name' => "Mr. Nobody & comp",
        'boolean' => 1,
        'without' => '',
           'mask' => 'test',
);

$file = GetRc->new ('/tmp/aliases');
$file->ofs(' = ');
$retval = $file->writerc(\%data);

print "not " if ( $retval );

print "ok 1\n";
