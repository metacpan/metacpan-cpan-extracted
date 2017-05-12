######################################################################
# docwrite()
######################################################################

print "1..1\n";

$init = "";
require "t/init.pl";

my $source = <<EOT;
$init
document.write("abc");
EOT
my $oks = 0;
my $nof = 100;

for my $i (1..$nof) {
    my $rc = $js->eval($source);
    die "eval returned undef" unless $rc;
    if($js->property_get("navigator.appVersion") eq "3") {
        $oks++;
    }
}

if($nof != $oks) {
    print "not ";
}

print "ok 1\n";

$js->destroy();
