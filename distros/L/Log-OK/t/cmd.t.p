use strict;
use warnings;
use feature "say";

use Log::OK {
        lvl=>"error",
        opt=>"verbose",
        sys=>"Log::ger"
};


say Log::OK::FATAL||0;
say Log::OK::ERROR||0;
say Log::OK::WARN||0;
say Log::OK::INFO||0;
say Log::OK::DEBUG||0;
say Log::OK::TRACE||0;

