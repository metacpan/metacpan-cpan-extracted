use Test::More tests => 1;
use JavaScript::Sprockets;

my $sp = JavaScript::Sprockets->new(
  root => "t",
  load_paths => ["javascripts"],
);

my $correct;
open my $fh, '<', 't/output/correct.js' or die $!;
{
  local $/;
  $correct = <$fh>;
}

my $js = $sp->concatenation("test.js");
is $js, $correct, "correct concatenation";

done_testing();