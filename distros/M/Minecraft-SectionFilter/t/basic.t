
use strict;
use warnings;
use utf8;

use Test::More 0.9501;
use Minecraft::SectionFilter;
use Term::ANSIColor qw( color );

my $sample = "§fhelloworld§4test§rdone";

sub safely(&) {
  my $code = shift;
  local $@;
  my $failed = 1;
  eval { $code->(); undef $failed };
  if ($failed) {
    @_ = ("Did not run safely");
    diag $@;
    goto &fail;
  }
}

subtest direct => sub {
  safely { is( Minecraft::SectionFilter::strip_sections($sample), 'helloworldtestdone', "Strip works" ); };
  safely {
    is(
      Minecraft::SectionFilter::ansi_encode_sections($sample),
      color('bright_white') . 'helloworld' . color('red') . 'test' . color('reset') . 'done',
      "Colorise works"
    );
  };

};

subtest exports => sub {
  safely { is( strip_sections($sample), 'helloworldtestdone', "Strip works" ); };
  safely {
    is(
      ansi_encode_sections($sample),
      color('bright_white') . 'helloworld' . color('red') . 'test' . color('reset') . 'done',
      "Colorise works"
    );
  };
};
done_testing();
