######################################################################
# Testcase:     Set/Get properties of objects
# Revision:     $Revision: 1.1.1.1 $
# Last Checkin: $Date: 2006/02/01 06:00:49 $
# By:           $Author: mschilli $
#
# Author: Mike Schilli m@perlmeister.com, 2002
######################################################################

use warnings;
use strict;

print "1..5\n";

use JavaScript::SpiderMonkey;
my $js = JavaScript::SpiderMonkey->new();
$js->init();

$js->property_by_path("navigator.appName");
$js->property_by_path("navigator.userAgent");
$js->property_by_path("navigator.appVersion");
$js->property_by_path("document.cookie");
$js->property_by_path("parent.location");
$js->property_by_path("document.location.href");
$js->property_by_path("document.location.yodel");

    # Function to write something from JS to a Perl $buffer
my $buffer;
my $doc = $js->object_by_path("document");
$js->function_set("write", sub { $buffer .= join('', @_) }, $doc);
$buffer = "";

my $code = <<EOT;
  navigator.appName      = "Netscape";
  navigator.appVersion   = "3";
  navigator.userAgent    = "Grugenheimer";
  document.cookie        = "k=v; domain=.netscape.com";
  parent.location        = "http://www.aol.com";
  document.write(navigator.userAgent);
EOT

my $rc = $js->eval($code);

# Check return code
print "not " if $rc != 1;
print "ok 1\n";

# Check simple property
print "not " unless $js->property_get("navigator.appName") eq "Netscape";
print "ok 2\n";

# Check simple property
print "not " unless $js->property_get("navigator.appVersion") eq "3";
print "ok 3\n";

# Check simple property
print "not " unless 
    $js->property_get("document.cookie") eq "k=v; domain=.netscape.com";
print "ok 4\n";

# Check buffer from document.write()
print "not " unless $buffer eq "Grugenheimer";
print "ok 5\n";
