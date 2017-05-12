use strict;
use Test::More tests => 3;

our %CONFIG;
do 't/testcommon.pl';

use File::Temp;
use Net::POP3;

END {ok(0, 'loaded') unless $::loaded;}
use Mail::POP3;
$::loaded = 1;
ok(1, 'loaded');

my $config_text = << "EOF";
{
  'port' => '6110',
  'max_servers' => 10,
  'mpopd_pid_file' => '$CONFIG{outdir}/mpopd.pid',
  'mpopd_pam_service' => 'mpopx',
  'trusted_networks' => '/usr/local/mpopd/mpopd_trusted',
  'userlist' => '.userlist',
  'mpopd_failed_mail' => '$CONFIG{outdir}/mpopd_failed_mail',
  'host_mail_path' => '/var/spool/popmail',
  'mpopd_spool' => '$CONFIG{outdir}/mpopd_spool',
  'receivedfrom' => 'fredo.co.uk',
  'passsecret' => 1,
  'greeting' => 'mpopd V3.x',
  'addreceived' => {
    'bob' => 1
  },
  'user_log' => {
    'markjt' => 1
  },
  'message_start' => '^From ',
  'message_end' => '^\\s+\$',
  'mailgroup' => 12,
  'retry_on_lock' => 0,
  'mail_spool_dir' => '/var/spool/mail',
  'mpopd_conf_version' => '$Mail::POP3::VERSION',
  'debug' => 1,
  'hosts_allow_deny' => '/usr/local/mpopd/mpopd_allow_deny',
  'timezone' => 'GMT',
  'timeout' => 10,
  'user_log_dir' => '$CONFIG{outdir}/mpopd_log',
  'debug_log' => '$CONFIG{outdir}/mpopd.log.main',
  'reject_bogus_user' => 0,
  'allow_non_fqdn' => 1,
  'user_debug' => {
  },
  'connection_class' => 'Mail::POP3::Security::Connection',
  fork_alert => ">/usr/local/mpopd/fork_alert",
  user_check => sub { 1 },
  password_check => sub { 1 },
  mailbox_class => 'Mail::POP3::Folder::mbox::parse_to_disk',
}
EOF

my $fake_mbox = File::Temp->new;
print $fake_mbox $CONFIG{fake_mbox_text};
$fake_mbox->seek(0, Fcntl::SEEK_SET);
my $tmpdir = File::Temp->newdir;
my $config = Mail::POP3->read_config($config_text);
$config->{mailbox_args} = sub {
  (
    $<,
    $(,
    $fake_mbox,
    '^From ',
    '^\\s*$',
    $tmpdir,
    0, # debug
  );
};
ok(1, 'config read');

my $tmpfh = File::Temp->new;
$tmpfh->print(<<EOF);
USER bob
PASS bob1
UIDL
TOP 3 2
RETR 3
DELE 2
UIDL
QUIT
EOF
my $receivedheader = "Received: from fredo.co.uk\n    by mpopd V$Mail::POP3::VERSION";
my $msg3receivednofrom = "$receivedheader\n$CONFIG{msg3nofrom}";
my $msg3receivednofromCRLF = $msg3receivednofrom;
$msg3receivednofromCRLF =~ s#\n#\015\012#g;
my $msg3length = length($msg3receivednofromCRLF) + 43; # 43 = length " for bob"
my $pop3_ref = <<EOF;
+OK mpopd V3.x
+OK bob send me your password
+OK thanks bob...
+OK unique-id listing follows
1 <$CONFIG{msgid1}>
2 <$CONFIG{msgid2}>
3 <$CONFIG{msgid3}>
.
+OK top of message 3 follows
$receivedheader
$CONFIG{msg3topnofrom}.
+OK $msg3length octets
$msg3receivednofrom.
+OK message 2 flagged for deletion
+OK unique-id listing follows
1 <$CONFIG{msgid1}>
3 <$CONFIG{msgid3}>
.
+OK TTFN bob...
EOF
$tmpfh->seek(0, Fcntl::SEEK_SET);
my $server = Mail::POP3::Server->new($config);
my $tmpfh2 = File::Temp->new;
if (my $kid = fork) {
  waitpid $kid, 0;
} else {
  $server->start($tmpfh, $tmpfh2, '127.0.0.1');
  exit;
}
$tmpfh2->seek(0, Fcntl::SEEK_SET);
my $pop3 = join '', <$tmpfh2>;
$pop3 =~ s#^\s*for bob.*?\r\n##gm;
$pop3_ref =~ s#\n#\015\012#g;
#print Data::Dumper::Dumper($pop3, $pop3_ref);
ok($pop3 eq $pop3_ref, 'talk pop3 to server');

undef $tmpdir;
