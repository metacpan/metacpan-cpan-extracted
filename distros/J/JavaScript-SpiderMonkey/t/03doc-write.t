######################################################################
# Set and retrieve document.location.href
######################################################################

print "1..1\n";

$init = "";
require "t/init.pl";

my $source = <<EOT;
$init
document.write("abc");
EOT

my $rc = $js->eval($source);
die "eval returned undef" unless $rc;
if($js->property_get("navigator.appVersion") ne "3") {
    print "not ";
}

print "ok 1\n";
