use strict;
use warnings;
use Test::More tests => 1;
use Log::Any;

{
    my $buf = '';
    open my $fh, ">", \$buf;
    local *STDERR = $fh;

    my $log = Log::Any->get_logger(
        default_adapter => ['Stderr', log_level => 'error']
    );
    # check if log_level spewas applied
    ok( 
        ( ! $log->is_warn and $log->is_error),
        "log_level specified in default_adapter was applied"
    );
}
