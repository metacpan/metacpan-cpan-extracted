# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 16;    # last test to print
use Log::Log4perl::Tiny qw( :easy get_logger );

use lib 't';
use TestLLT qw( set_logger log_is log_like );

Log::Log4perl->easy_init(
   {
      format => '%m',
      level  => $INFO,
   }
);
set_logger(get_logger());

log_is { shift->info('whatever') } 'whatever',
  'info, no sub to call (baseline)';

log_is {
   shift->info(sub { 'whatever' })
}
'whatever', 'info, sub to call (baseline)';

log_is {
   shift->warn(sub { 'whatever' })
}
'whatever', 'warn, sub to call (baseline)';

{
   # capture stuff to check it
   my @call_args;
   local $SIG{__WARN__} = sub { @call_args = @_ };

   log_is {
      shift->logwarn(sub { 'whatever' })
   }
   'whatever', 'logwarn, sub to call (non-regression)';
   is scalar(@call_args), 1, 'right number of call args for logwarn';
   like $call_args[0], qr{(?mxs:whatever .* line)},
     'right call args for logwarn';

   my $eval_failed = 1;
   log_is {
      eval {
         shift->logdie(sub { 'whatever' });
         $eval_failed = 0;
      }
   } ## end log_is
   'whatever', 'logdie, sub to call (non-regression)';
   is $eval_failed, 1, 'logdie threw exception';
   is scalar(@call_args), 1, 'right number of call args for logdie';
   like $call_args[0], qr{(?mxs:whatever .* line)},
     'right call args for logdie';

   log_like {
      shift->logcarp(sub { 'whatever' })
   }
   qr{(?mxs:whatever \s at .* line)},
     'logcarp, sub to call (non-regression)';
   is scalar(@call_args), 1, 'right number of call args for logcarp';
   like $call_args[0], qr{(?mxs:whatever .* line)},
     'right call args for logcarp';

   log_like {
      shift->logcluck(sub { 'whatever' })
   }
   qr{(?mxs: whatever \s at .*? line .*?  main:: .*?  TestLLT:: )},
     'logcluck, sub to call (non-regression)';
   is scalar(@call_args), 1, 'right number of call args for logcluck';
   like $call_args[0],
     qr{(?mxs: whatever \s at .*? line .*?  main:: .*?  TestLLT:: )},
     'right call args for logcluck';
}

done_testing();
