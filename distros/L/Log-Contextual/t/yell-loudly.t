use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Log::Contextual qw(:log);

like(
   exception { Log::Contextual::set_logger() },
   qr/set_logger is no longer a direct sub in Log::Contextual/,
   'Log::Contextual::set_logger dies',
);

like(
   exception { Log::Contextual::with_logger() },
   qr/with_logger is no longer a direct sub in Log::Contextual/,
   'Log::Contextual::with_logger dies',
);

done_testing;
