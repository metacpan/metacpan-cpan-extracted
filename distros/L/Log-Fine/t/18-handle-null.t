#!perl -T

use Test::More tests => 3;

use Log::Fine;
use Log::Fine::Handle::Null;
use Log::Fine::Levels::Syslog qw( :masks );

{

        my $handle =
            Log::Fine::Handle::Null->new(name => "devnull",
                                         mask => LOGMASK_DEBUG | LOGMASK_INFO | LOGMASK_NOTICE);

        isa_ok($handle, "Log::Fine::Handle::Null");
        can_ok($handle, "msgWrite");

        my $return_value = $handle->msgWrite(INFO, "Goes Nowhere.  Does Nothing.");

        isa_ok($handle, "Log::Fine::Handle::Null");

}
