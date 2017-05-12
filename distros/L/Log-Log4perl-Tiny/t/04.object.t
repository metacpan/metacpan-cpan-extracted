# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 109;    # last test to print

#use Test::More 'no_plan';
use Log::Log4perl::Tiny qw( :levels );

use lib 't';
use TestLLT qw( set_logger log_is log_like );

my $logger = Log::Log4perl::Tiny::get_logger();
ok($logger, 'got a logger instance');
set_logger($logger);

my @names = qw( trace debug info warn error fatal );
my @levels = ($TRACE, $DEBUG, $INFO, $WARN, $ERROR, $FATAL);
for my $i (0 .. $#names) {
   $logger->level($levels[$i]);

   my $current = $names[$i];

   my $blocked = 1;
   for my $name (@names) {
      my $isfunc_perlish   = 'is_' . $name;
      my $isfunc_javaesque = 'is' . ucfirst($name) . 'Enabled';
      $blocked = 0 if $name eq $current;
      if ($blocked) {
         log_is { $logger->$name("whatever $name") } '',
           "minimum level $current, nothing at $name level";
         is($logger->$isfunc_perlish,   0, "is $name false");
         is($logger->$isfunc_javaesque, 0, "is $name false (Java-esque)");
      } ## end if ($blocked)
      else {
         log_like { $logger->$name("whatever $name") }
         qr/whatever\ $name/mxs,
           "minimum level $current, something at $name level";
         is($logger->$isfunc_perlish,   1, "is $name true");
         is($logger->$isfunc_javaesque, 1, "is $name true (Java-esque)");
      } ## end else [ if ($blocked)
   } ## end for my $name (@names)
} ## end for my $i (0 .. $#names)
