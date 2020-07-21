use Modern::Perl;
use Test::More qw(no_plan);
use Data::Dumper;
require Log::LogMethods;

my @order=sort { $Log::LogMethods::LEVEL_MAP{$b} <=> $Log::LogMethods::LEVEL_MAP{$a} } keys %Log::LogMethods::LEVEL_MAP;

my @cmp=(qw(
  OFF
  ALWAYS
  FATAL
  ERROR
  WARN
  INFO
  DEBUG
  TRACE)
);

foreach my $level (@cmp) {
  cmp_ok(shift(@order),'eq',$level,"Should be $level");
}
