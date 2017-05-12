######################################################################
# functions2
######################################################################

print "1..1\n";

$init = "";
require "t/init.pl";

$args = "";

my $docobj = $js->object_by_path("document");
$js->function_set("schnubbel", sub { $args = join '', @_; });

my $source = <<EOT;
$init
document.schnubbel("abc", "def", 3, 5, 8);
EOT

my $rc = $js->eval($source);

die "eval returned undef" unless $rc;

if($args ne "abcdef358") {
    print "not ";
}

print "ok 1\n";

$js->destroy();
