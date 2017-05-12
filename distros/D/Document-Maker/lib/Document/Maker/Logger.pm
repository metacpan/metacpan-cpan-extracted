package Document::Maker::Logger;

use Log::Log4perl qw/:easy get_logger/;
use Sub::Exporter -setup => {
    exports => [ qw/get_logger/ ],
    groups => { default => [ qw/get_logger/ ] },
};

Log::Log4perl->easy_init;

1;
