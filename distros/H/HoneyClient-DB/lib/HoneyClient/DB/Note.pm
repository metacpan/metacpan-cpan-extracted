use strict;
use HoneyClient::DB;

package HoneyClient::DB::Note;

use base ("HoneyClient::DB");

BEGIN {
    our %fields = (
        text => {
            note => {
                required => 1,
            },
        },
        timestamp => {
            time => {
                init_val => 'CURRENT_TIMESTAMP()',
            },
        },
        string => {
            category => {
                required => 1,
            },
            analyst => {
                required => 1,
            },
        },
    );
}

1;
