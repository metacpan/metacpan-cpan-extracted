package # PAUSE HIDE
    Collectd;
use strict;
use warnings;

BEGIN {
    $INC{'Collectd.pm'} = 1;
}

use constant TYPE_READ => 'READ';
use constant TYPE_WRITE => 'WRITE';
use constant TYPE_INIT => 'INIT';
use constant TYPE_CONFIG => 'CONFIG';

use constant LOG_WARNING => 'WARNING';

sub plugin_register {}

sub plugin_log { warn @_ }

1;

