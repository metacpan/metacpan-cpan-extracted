use lib ('../../lib');
use Lego::Ldraw;
use Lego::Ldraw::POV;

$\ = "\n";

my $l = Lego::Ldraw->new_from_file($ARGV[0]);

print $l->POVdesc;
