use Test::More tests => 19;

my $facility1 = LOG_AUTH;
my $severity1 = LOG_INFO;
my $sender1   = 'calvin';
my $name1     = 'popsicle';
my $pid1      = $$;

my $logger = $CLASS->new(LOG_UDP, 'localhost', 514, $facility1, $severity1, $sender1, $name1);

is($logger->get_facility, $facility1, 'initial facility');
is($logger->get_severity, $severity1, 'initial severity');
is($logger->get_priority, ($facility1 << 3) | $severity1, 'initial priority');
is($logger->get_sender, $sender1, 'initial sender');
is($logger->get_name, $name1, 'initial name');
is($logger->get_pid, $pid1, 'initial pid');

my $facility2 = LOG_LOCAL1;
my $severity2 = LOG_WARNING;
my $sender2   = 'hobbes';
my $name2     = 'trex';
my $pid2      = int($$ / 2) + 1;

$logger->set_facility($facility2);
ok(!$@, 'set facility');
$logger->set_severity($severity2);
ok(!$@, 'set severity');
$logger->set_sender($sender2);
ok(!$@, 'set sender');
$logger->set_name($name2);
ok(!$@, 'set name');
$logger->set_pid($pid2);
ok(!$@, 'set pid');

is($logger->get_facility, $facility2, 'second facility');
is($logger->get_severity, $severity2, 'second severity');
is($logger->get_priority, ($facility2 << 3) | $severity2, 'second priority');
is($logger->get_sender, $sender2, 'second sender');
is($logger->get_name, $name2, 'second name');
is($logger->get_pid, $pid2, 'second pid');

my $facility3 = LOG_LOCAL7;
my $severity3 = LOG_DEBUG;

$logger->set_priority($facility3, $severity3);
ok(!$@, 'set priority');
is($logger->get_priority, ($facility3 << 3) | $severity3, 'third priority');

1;