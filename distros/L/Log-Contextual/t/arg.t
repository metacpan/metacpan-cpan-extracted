use strict;
use warnings;

use Log::Contextual::SimpleLogger;
use Test::More;
my $var_log;
my $var;

my @levels = qw(debug trace warn info error fatal);

BEGIN {
  $var_log = Log::Contextual::SimpleLogger->new({
    levels  => [qw(trace debug info warn error fatal)],
    coderef => sub { $var = shift }
  })
}

use Log::Contextual qw{ :log :dlog}, -logger => $var_log;

my @args = qw(fizz buzz fizzbuzz);

for my $level (@levels) {
  for my $prefix (qw(log logS Dlog DlogS)) {

    my $original = local $_ = "don't tread on me";
    my $method_name = "${prefix}_${level}";
    my $ref         = __PACKAGE__->can($method_name)
      or die "no ref found for method $method_name";

    $ref->(sub { "$method_name" }, @args);
    ok($_ eq $original, "\$_ was not disturbed by $method_name");
    ok($var eq "[$level] $method_name\n", "log argument was correct");
  }
}

done_testing;
