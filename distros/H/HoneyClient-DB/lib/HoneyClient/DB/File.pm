use strict;
use HoneyClient::DB;
use HoneyClient::DB::Note;

package HoneyClient::DB::File::Content;

use base ("HoneyClient::DB");

BEGIN {
    our %fields = (
        string => {
            md5 => {
                required => 1,
                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
            },
            sha1 => {
                required => 1,
                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
            },
            type => {
                required => 1,
            }
        },
        uint => {
            size => {
                required => 1,
            }
        },
        # Add Status
        array => {
            notes => {
                objclass => 'HoneyClient::DB::Note',
            }
        },
    );
}

package HoneyClient::DB::File;

use base("HoneyClient::DB");

BEGIN {

    our %fields = (
        string => {
            name => {
                required => 1,
                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
            },
        },
        ref => {
            content => {
                objclass => 'HoneyClient::DB::File::Content',
                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
            },
        },
        int => {
            status => {
                required => 1,
                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
            },
        },
        timestamp => {
            mtime => {
                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
            },
        },
    );
}

1;
