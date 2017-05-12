package Gantry::State::Constants;

use strict; 
use warnings;

BEGIN {
    use Exporter();
    use vars qw (@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    @ISA = qw(Exporter);
    @EXPORT_OK = qw();
    @EXPORT = qw (
        STATE_FINI
        STATE_POST_ENGINE_INIT 
        STATE_PRE_INIT
        STATE_INIT
        STATE_POST_INIT
        STATE_CACHED_PAGES
        STATE_PRE_ACTION
        STATE_ACTION
        STATE_POST_ACTION
        STATE_REDIRECT
		STATE_DECLINED
        STATE_SET_HEADERS
        STATE_PRE_PROCESS
        STATE_PROCESS
        STATE_POST_PROCESS
        STATE_CHECK_STATUS
        STATE_OUTPUT
        STATE_SEND_STATUS
    );

    %EXPORT_TAGS = qw();
    
}

use constant {
    STATE_FINI => 0,
    STATE_POST_ENGINE_INIT => 1,
    STATE_PRE_INIT => 2,
    STATE_INIT => 3,
    STATE_POST_INIT => 4,
    STATE_CACHED_PAGES => 5,
    STATE_PRE_ACTION => 6,
    STATE_ACTION => 7,
    STATE_POST_ACTION => 8,
    STATE_REDIRECT => 9,
	STATE_DECLINED => 10,
    STATE_SET_HEADERS => 11,
    STATE_PRE_PROCESS => 12,
    STATE_PROCESS => 13,
    STATE_POST_PROCESS => 14,
    STATE_CHECK_STATUS => 15,
    STATE_OUTPUT => 16,
    STATE_SEND_STATUS => 17
};

1;

