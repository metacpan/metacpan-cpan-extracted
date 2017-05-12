use strict;
use HoneyClient::DB;
use HoneyClient::DB::Note;

package HoneyClient::DB::Regkey::Entry;

use base("HoneyClient::DB");

BEGIN {

    #our ($UNIQUE_NOT,$UNIQUE_SELF,$UNIQUE_MULT) = (0,1,2);
    #our (%fields,%types,%check,%required);

    our %fields = (
		text => [ 'name', 'new_value', 'old_value' ],

# XXX: Commented out, due to variable length unique keys.
#        text => {
#            name => {
#                #required => 1,
#                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
#            },
#            new_value => {
#                #required => 1,
#                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
#            },
#            old_value => {
#                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
#            },
#        },
    );
}

package HoneyClient::DB::Regkey;

use base("HoneyClient::DB");

BEGIN {

    #our ($UNIQUE_NOT,$UNIQUE_SELF,$UNIQUE_MULT) = (0,1,2);
    #our (%fields,%types,%check,%required);

    our %fields = (
        string => {
            key_name => {
                required => 1,
                key => $HoneyClient::DB::KEY_UNIQUE_MULT,
            },
        },
        array => {
            entries => {
                objclass => 'HoneyClient::DB::Regkey::Entry',
            },
            notes => {
                objclass => 'HoneyClient::DB::Note',
            },
        },
        int => {
        	status => {
        		required => 1,
        		key => $HoneyClient::DB::KEY_UNIQUE_MULT,
        	},
        },
        timestamp => {
        	'time' => {
#        		required => 1,
        		key => $HoneyClient::DB::KEY_UNIQUE_MULT,
        	}
        }
    );
}

1;
