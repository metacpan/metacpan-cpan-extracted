use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Log::Sprintf;

my $log_formatter = Log::Sprintf->new({
   category => 'DeployMethod',
   format   => '[%p][%c] %m',
});

is $log_formatter->format, '[%p][%c] %m', 'format gets stored correctly';

my $args = {
  priority => 'trace',
  message => 'starting connect',
};

is($log_formatter->sprintf($args), '[trace][DeployMethod] starting connect', 'log formats correctly');

is($log_formatter->sprintf({
   message => 'x',
   priority => 'trace',
   format => ']%{1}p[ %{useless}m',
}), ']t[ x', 'log formats correctly with arguments passed to method');

is($log_formatter->sprintf({
   message => "woot\n",
   format => '%{chomp}m',
}), 'woot', 'chomp option for %m works');

ok exception { $log_formatter->sprintf({ message => 'x', format => '%L' }) },
   'checking accessors for plain accessor works';

for (
   [l => 'location'], [m => 'message'], [d => 'date'],
   [p => 'priority'], [T => 'stacktrace']
) {
   ok exception {
      $log_formatter->sprintf({ format => "%$_->[0]" })
   }, "checking accessors for $_->[1] works";
}

{
   my $date_formatter = Log::Sprintf->new({
      format   => '[%d] %m',
   });

   is($date_formatter->sprintf({
      message => 'lol',
      date    => [1, 2, 3, 4, 5, 106, 1, 341, 1],
   }), '[2006-06-04 03:02:01] lol', 'date formats correctly');
}

{

   my $st_formatter = Log::Sprintf->new({
      format   => '%m at %T',
   });

   my $st = [
    [
      "main", "t/stacktrace.t", 24, "Log::Structured::log_event", 1, undef, undef,
      undef, 1538, "\377\377\377\377\377\377\377\377\377\377\377\377", undef
    ],
    [
      "main", "t/stacktrace.t", 22, "main::biff", 1, undef, undef, undef, 1538,
      "\377\377\377\377\377\377\377\377\377\377\377\377", undef
    ],
    [
      "main", "t/stacktrace.t", 21, "main::baz", 1, undef, undef, undef, 1538,
      "\377\377\377\377\377\377\377\377\377\377\377\377", undef
    ],
    [
      "main", "t/stacktrace.t", 20, "main::bar", 1, undef, undef, undef, 1538,
      "\377\377\377\377\377\377\377\377\377\377\377\377", undef
    ],
    [
      "main", "t/stacktrace.t", 27, "main::foo", 1, undef, undef, undef, 1794,
      "\377\377\377\377\377\377\377\377\377\377\377\377", undef
    ]
   ];

   my $trace = "t/stacktrace.t line 24\n" .
      "\tmain::biff called at t/stacktrace.t line 22\n" .
      "\tmain::baz called at t/stacktrace.t line 21\n" .
      "\tmain::bar called at t/stacktrace.t line 20\n" .
      "\tmain::foo called at t/stacktrace.t line 27";

   is($st_formatter->sprintf({
      message => 'lol',
      stacktrace => $st,
   }), "lol at $trace", 'stacktrace formats correctly');
}

{
   my $loc_formatter = Log::Sprintf->new({
      format   => '[%l] %m',
   });

   is($loc_formatter->sprintf({
      message    => 'lol',
      subroutine => 'foo',
      file       => 'foo.t',
      line       => 35,
   }), '[foo (foo.t:35)] lol', 'location formats correctly');
}

done_testing;
