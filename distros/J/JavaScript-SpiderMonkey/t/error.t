use warnings;
use strict;
use JavaScript::SpiderMonkey;
use Test::More tests => 6;
my $jscode1 =<<EOF;
1 = 3;
EOF
my $js1 = JavaScript::SpiderMonkey->new ();
$js1->init ();
ok (!$js1->eval ($jscode1));
ok ($@ !~ "\n");
ok ($@ =~ "SyntaxError");
#print "$@\n";
my $jscode2 =<<EOF;
var fruit = non_existant_function ();
EOF
my $js2 = JavaScript::SpiderMonkey->new ();
$js2->init ();
ok (!$js2->eval ($jscode2));
ok ($@ !~ "\(null\)");
#print "$@\n";
ok ($@ =~ "ReferenceError");

# Local variables:
# mode: perl
# End:
