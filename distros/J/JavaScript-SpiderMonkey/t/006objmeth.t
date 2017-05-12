######################################################################
# Testcase:     Functions/Methods for different objects
# Revision:     $Revision: 1.1.1.1 $
# Last Checkin: $Date: 2006/02/01 06:00:49 $
# By:           $Author: mschilli $
#
# Author: Mike Schilli m@perlmeister.com, 2004
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);

use JavaScript::SpiderMonkey;
my $js = JavaScript::SpiderMonkey->new();
$js->init();

$js->property_by_path("document.location.href");
$js->property_by_path("document.location.yodel");
$js->property_by_path("document.someobj.someprop");

    # Function to write something from JS to a Perl $buffer
my $location_buffer;
my $doc = $js->object_by_path("document.location");
$js->function_set("write", sub { $location_buffer .= join('', @_) }, $doc);

my $someobj_buffer;
my $someobj = $js->object_by_path("document.someobj");
$js->function_set("write", sub { $someobj_buffer .= join('', @_) }, $someobj);

my $code = <<EOT;
  document.location.write("location message");
  document.someobj.write("someobj message");
EOT

my $rc = $js->eval($code);

# Check return code
ok($rc, "JS return code");

# Check location buffer
is($location_buffer, "location message", "check loc buffer");
is($someobj_buffer, "someobj message", "check someobj buffer");
