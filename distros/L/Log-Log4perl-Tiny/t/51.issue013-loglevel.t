# vim: filetype=perl :
use strict;
use warnings;

use Test::More;    # tests => 16;    # last test to print
use Log::Log4perl::Tiny qw( :easy get_logger );

use lib 't';
use TestLLT qw( set_logger log_is log_like capture_stderr );

Log::Log4perl->easy_init(
   {
      format => '%p %M %m%n',
      level  => $INFO,
   }
);

sub carpish_function {
   my $what = shift;
   if ($what eq 'carp')  { LOGCARP 'WHERE DOES THIS SHOW?' }
   if ($what eq 'cluck') { LOGCLUCK 'WHERE DOES THIS SHOW?' }
   if ($what eq 'croak') {
      eval { LOGCROAK 'WHERE DOES THIS SHOW?' }
   }
   if ($what eq 'confess') {
      eval { LOGCONFESS 'WHERE DOES THIS SHOW?' }
   }
} ## end sub carpish_function

{
   my $ste = capture_stderr {
      carpish_function('carp');
   };
   like $ste, qr{^WARN \s+ main::carpish_function\s}mxs,
     'LOGCARP yields WARN priority and right function';
}

{
   my $ste = capture_stderr {
      carpish_function('cluck');
   };
   like $ste, qr{^WARN\s}mxs,
     'LOGCLUCK yields WARN priority and right function';
}

{
   my $ste = capture_stderr {
      carpish_function('croak');
   };
   like $ste, qr{^FATAL\s}mxs,
     'LOGCROAK yields FATAL priority and right function';
}

{
   my $ste = capture_stderr {
      carpish_function('confess');
   };
   like $ste, qr{^FATAL\s}mxs,
     'LOGCONFESS yields FATAL priority and right function';
}

done_testing();
