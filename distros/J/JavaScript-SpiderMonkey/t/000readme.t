######################################################################
# Testcase:     Run the sample code from the README file
# Revision:     $Revision: 1.1.1.1 $
# Last Checkin: $Date: 2006/02/01 06:00:49 $
# By:           $Author: mschilli $
#
# Author: Mike Schilli m@perlmeister.com, 2002
######################################################################

use warnings;
use strict;

print "1..1\n";

open FILE, "<SpiderMonkey.pm" or die "Cannot open";
my $data = join '', <FILE>;
close FILE;

my $buffer = "";

    # Overwrite print() with our own routine filling $buffer
if(my($code) = ($data =~ /SYNOPSIS(.*?)=head1 INSTALL/s)) {
    $code =~ s/print /myprint/g;
    eval "sub myprint { \$buffer .= join('', \@_) } $code; 
          \$buffer.=\$rc;
          \$buffer.=\$url;";
}

if($buffer ne "URL is  http://www.aol.com\n1http://www.aol.com") {
    print "not ('$buffer')";
}

print "ok 1\n";
