# Version: MPL 1.1/GPL 2.0/LGPL 2.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is The Tinderbox Client.
#
# The Initial Developer of the Original Code is
# Zach Lipton.
# Portions created by the Initial Developer are Copyright (C) 2001
# the Initial Developer. All Rights Reserved.
#
# Contributor(s): Zach Lipton <zach@zachlipton.com>
#
# Alternatively, the contents of this file may be used under the terms of
# either the GNU General Public License Version 2 or later (the "GPL"), or
# the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# in which case the provisions of the GPL or the LGPL are applicable instead
# of those above. If you wish to allow use of your version of this file only
# under the terms of either the GPL or the LGPL, and not to allow others to
# use your version of this file under the terms of the MPL, indicate your
# decision by deleting the provisions above and replace them with the notice
# and other provisions required by the GPL or the LGPL. If you do not delete
# the provisions above, a recipient may use your version of this file under
# the terms of any one of the MPL, the GPL or the LGPL.

# This script developed August 2001 for Abisource and perl.


package Tindermail::Sendmail;
use Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw (sendstartmail sendendmail);

use Tinderconfig;
1;
sub sendstartmail { # to send the start email.
        $time = time();
        open(SENDMAIL, "|/usr/lib/sendmail -t") || 
                die "can't open sendmail"; # get sendmail open
        print SENDMAIL "From: tinderbox-client\@zachlipton.com\n";
        print SENDMAIL "To: ".$Tinderconfig::serveraddress."\n";
        print SENDMAIL "Subject: Tinderbox\n\n";

        print SENDMAIL "tinderbox: tree: $Tinderconfig::tinderboxpage\n";
        print SENDMAIL 'tinderbox: builddate: '.$time."\n";
        print SENDMAIL "tinderbox: status: building\n";
        print SENDMAIL "tinderbox: build: $Tinderconfig::boxname\n";
        print SENDMAIL "tinderbox: errorparser: unix\n"; 
        print SENDMAIL "tinderbox: buildfamily: unix\n";
        print SENDMAIL "tinderbox: START\n";

        close(SENDMAIL); # my work here is done.

}

sub sendendmail($$) {
        ($log, $state) = @_; # state is pass, fail, testfailed
        open(SENDMAIL, "|/usr/lib/sendmail -t") || 
                die "can't open sendmail"; # get sendmail open
        print SENDMAIL "From: tinderbox-client\@zachlipton.com\n";
        print SENDMAIL "To: ".$Tinderconfig::serveraddress."\n";
        print SENDMAIL "Subject: Tinderbox\n\n";

        print SENDMAIL "tinderbox: tree: $Tinderconfig::tinderboxpage\n";
        print SENDMAIL 'tinderbox: builddate: '.$time."\n";
        if ($state eq "pass") {
                print SENDMAIL "tinderbox: status: success\n";
        } elsif ($state eq "fail") {
                print SENDMAIL "tinderbox: status: busted\n";
        } elsif ($state eq "testfailed") {
                print SENDMAIL "tinderbox: status: testfailed\n";
        } else {
                print SENDMAIL "tinderbox: status: busted\n"; # something nuts happend
        }
        print SENDMAIL "tinderbox: build: $Tinderconfig::boxname\n";
        print SENDMAIL "tinderbox: errorparser: unix\n"; 
        print SENDMAIL "tinderbox: buildfamily: unix\n"; 
        print SENDMAIL "tinderbox: END\n\n";
        print SENDMAIL $log; # output our build log

        close(SENDMAIL); # and send the mail out
}

1;
