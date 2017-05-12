use strict;
use warnings;

use Test::More;
use Devel::Isa::Explainer qw( explain_isa );

{
  local $SIG{ALRM} = sub {
    ok( 0, "Alarm Triggered, Death Loop was entered" );
    done_testing;
    exit 1;
  };
  $Devel::Isa::Explainer::MAX_WIDTH = 2;
  alarm 1;
  explain_isa("Devel::Isa::Explainer");
  alarm 0;
}
pass("Did not enter death loop");
done_testing;

