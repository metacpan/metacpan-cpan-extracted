######################################################################
# functions
######################################################################

print "1..1\n";

$init   = "";
$buffer = "";
require "t/init.pl";

my $source = <<EOT;
$init
document.write("abc", "def");
document.write("abc2", "def2");
document.write("abc3", "def3");
document.write("abc4", "def4");
EOT

my $rc = $js->eval($source);
die "eval returned undef" unless $rc;

if($buffer ne "abcdefabc2def2abc3def3abc4def4") {
    print "not ";
}
print "ok 1\n";

$js->destroy();
