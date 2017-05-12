use strict;
use warnings;

use Test::More;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use HTTP::Status::Const qw/ :all /;
use HTTP::Status ':constants';

is $HTTP_OK, HTTP_OK, 'HTTP OK';
ok is_success($HTTP_OK), 'is_success';

is status_message($HTTP_OK), 'OK', 'status_message';

done_testing;

