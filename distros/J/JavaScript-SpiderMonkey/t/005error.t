######################################################################
# Testcase:     Produce an error and check $@
# Revision:     $Revision: 1.1.1.1 $
# Last Checkin: $Date: 2006/02/01 06:00:49 $
# By:           $Author: mschilli $
#
# Author: Mike Schilli m@perlmeister.com, 2004
######################################################################

use warnings;
use strict;

use JavaScript::SpiderMonkey;

print "1..1\n";

my $js = JavaScript::SpiderMonkey->new();
$js->init();

my $code = <<EOT;
  foo = "bar;
EOT

$js->eval($code);

if($@ =~ /unterminated string literal/) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}
