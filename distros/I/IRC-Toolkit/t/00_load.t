use Test::More;
use strict; use warnings FATAL => 'all';

BEGIN { use_ok( 'IRC::Toolkit' ) }
can_ok( 'main', $_ ) for 
  ## Case
  qw/ lc_irc uc_irc eq_irc /,
  ## Colors
  qw/ color /,
  ## CTCP
  qw/ ctcp_quote ctcp_unquote ctcp_extract /,
  ## Masks
  qw/ matches_mask normalize_mask parse_user /,
  ## Modes
  qw/ mode_to_array mode_to_hash /,
  ## Parser
  qw/ irc_ref_from_line irc_line_from_ref /,
;
done_testing;
