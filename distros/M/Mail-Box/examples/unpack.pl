#!/usr/bin/perl
#
# Read a message from stdin, for instance from a '.forward' file
#       | unpack.pl
# The files get unpacked.

# This code can be used and modified without restriction.
# Mark Overmeer, <mailbox@overmeer.net>, 29 jan 2010

use warnings;
use strict;

use Errno  'EEXIST';
use POSIX  'strftime';

use Mail::Message  ();
use MIME::Types    ();

### configure this:
my $workdir = '/tmp/incoming';

# create the common work directory
-d $workdir
    or mkdir $workdir
    or die "cannot create unpack directory $workdir: $!\n";

# Create a unique unpack directory for this message
# More than one message can arrive in a second, even in parallel
my $unpackdir;
my $now = strftime "%Y%m%d-%T", localtime;

UNIQUE:
for(my $unique = 1; ; $unique++ )
{   $unpackdir = "$workdir/$now-$unique";
    mkdir $unpackdir and last;
    $!==EEXIST
        or die "cannot create unpack directory $unpackdir: $!";
}

# Read the message from STDIN
my $from_line = <>;    # usually added by the local MTA
my $msg = Mail::Message->read(\*STDIN);

# Shows message structure
# $msg->printStructure;

my $mime_types = MIME::Types->new;
my $partnr     = '00';

foreach my $part ($msg->parts('RECURSE'))
{   my $body     = $part->decoded;
    my $type     = $mime_types->type($body->mimeType);

    # some message parts will contain a filename
    my $dispfn   = $body->dispositionFilename || '';
    my $partname = $partnr++ . (length $dispfn ? ".$dispfn" : '');

    # try to find a nice filename extension if not yet known
    unless($partname =~ /\.\w{3,5}$/)
    {   my $ext    = $type ? ($type->extensions)[0] : undef;
        $partname .= ".$ext" if $ext;
    }

    my $filename  = "$unpackdir/$partname";
#print "$filename\n";

    if($type->isBinary)
    {   open OUT, '>:raw', $filename
           or die "cannot create binary part file $filename: $!";
    }
    else
    {   open OUT, '>:encoding(utf-8)', $filename
           or die "cannot create text part file $filename: $!";
    }

    $body->print(\*OUT);
    close OUT
        or warn "write errors to $filename: $!";
}
