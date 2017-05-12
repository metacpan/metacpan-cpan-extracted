use Test::More;
use Test::Fatal;

use_ok 'Linux::Systemd::Journal::Read';

my $jnl = new_ok 'Linux::Systemd::Journal::Read';

is exception { $jnl->seek_tail }, undef, 'Moved cursor to tail';

is exception { $jnl->previous }, undef, 'Moved cursor to previous entry';

is exception { $jnl->seek_head }, undef, 'Moved cursor to head';

done_testing;
