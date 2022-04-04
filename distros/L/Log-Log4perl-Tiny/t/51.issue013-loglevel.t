# vim: filetype=perl :
use strict;
use warnings;

use Test::More;    # tests => 16;    # last test to print
use Log::Log4perl::Tiny qw( :easy get_logger );

use lib 't';
use TestLLT qw( set_logger log_is log_like capture_stderr );

Log::Log4perl->easy_init(
   {
      format => '%p %m%n',
      level  => $INFO,
   }
);

{
   my $ste = capture_stderr {
      eval { LOGCARP 'WHERE DOES THIS?' }
   };
   like $ste, qr{^WARN\s}mxs, 'LOGCARP yields WARN priority';
}

{
   my $ste = capture_stderr {
      eval { LOGCLUCK 'WHERE DOES THIS?' }
   };
   like $ste, qr{^WARN\s}mxs, 'LOGCLUCK yields WARN priority';
}

{
   my $ste = capture_stderr {
      eval { LOGCROAK 'WHERE DOES THIS?' }
   };
   like $ste, qr{^FATAL\s}mxs, 'LOGCROAK yields FATAL priority';
}

{
   my $ste = capture_stderr {
      eval { LOGCONFESS 'WHERE DOES THIS?' }
   };
   like $ste, qr{^FATAL\s}mxs, 'LOGCONFESS yields FATAL priority';
}

done_testing();
