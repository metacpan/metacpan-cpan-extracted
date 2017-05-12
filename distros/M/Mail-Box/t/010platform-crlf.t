#!/usr/bin/env perl
# On Windows, the test mailbox must be have lines which are
# separated by CRLFs.  The mbox.src which is supplied is UNIX-style,
# so only has LF line-terminations.  In this script, this is
# translated.  The Content-Length of the messages is updated too.

use strict;
use warnings;

use Mail::Box::Test;

use Test::More tests => 1;

use FileHandle;

my $crlf = "\015\012";

open SRC,  '<', $unixsrc  or die "Cannot open $unixsrc to read: $!\n";
binmode SRC;

open DEST, '>', $winsrc or die "Cannot open $winsrc for writing: $!\n";
select DEST;
binmode DEST;

until(eof SRC)
{
    my ($lines, $bytes);

  HEADER:
    while(<SRC>)
    {   s/[\012\015]*$/$crlf/;

           if( m/^Content-Length\: / ) {$bytes = $' +0}
        elsif( m/^Lines\: /          ) {$lines = $' +0}
        elsif( m/^\s*$/              )
        {   # End of header
            if(defined $bytes && defined $lines)
            {   $bytes += $lines;
                print "Content-Length: $bytes\015\012";
            }

            print "Lines: $lines$crlf"
                if defined $lines;

            print $crlf;
            last HEADER;
        }
        else {print}
    }

  BODY:
    while(<SRC>)
    {   s/[\012\015]*$/$crlf/;
        print;
        last BODY if m/^From /;
    }
}

die "Errors in reading $unixsrc"  unless close SRC;
die "Errors in writing $winsrc"   unless close DEST;

pass("Folder conversion complete");
