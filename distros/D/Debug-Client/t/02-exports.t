use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 2;

BEGIN {
	use_ok( 'Debug::Client' );
}

######
# let's check our subs/methods.
######

my @subs = qw( get_buffer get_filename get get_h_var get_lineinfo get_options get_p_exp
	get_stack_trace get_v_vars get_value get_x_vars get_y_zero
	list_subroutine_names module new quit remove_breakpoint get_row run
	set_breakpoint set_option show_breakpoints show_line show_view show_line step_in step_over
	toggle_trace );


can_ok( 'Debug::Client', @subs );

done_testing();

__END__

