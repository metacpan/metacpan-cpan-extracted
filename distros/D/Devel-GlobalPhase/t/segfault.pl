use strict;
use warnings;
use File::Spec;

require Devel::GlobalPhase;
Devel::GlobalPhase->import;
my $layers = 0;
for (@ARGV) {
  /^--layers=(.*)$/ and $layers = $1, next;
  die "invalid option $_\n";
}
my $code = "END {\n" . ( "(sub {\n" x $layers ) . <<'END_CODE' . ("})->()\n" x $layers) . "}\n1";
  my $phase = global_phase;
  print "$phase\n";
END_CODE
eval $code or die $@;

{
  eval('sub { exit }')->();
}
