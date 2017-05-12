use Test::More;
use strict; use warnings FATAL => 'all';

BEGIN { 
  use_ok( 'IRC::Toolkit', qw/Masks Modes/ )
}
can_ok( 'main', $_ ) for 
  ## Masks
  qw/ matches_mask normalize_mask parse_user /,
  ## Modes
  qw/ mode_to_array mode_to_hash /,
;

ok( !main->can($_), "did not import $_" ) for qw/
  uc_irc eq_irc
  irc_ref_to_line irc_line_to_ref
/;

{
  my $warned;
  local $SIG{__WARN__} = sub { $warned = 1 };
  eval {; IRC::Toolkit->import(qw/Case Colors Foo/) };
  like $@, qr/import/, 'bad import dies ok';
  ok $warned, 'bad import warned ok';
}

done_testing;
