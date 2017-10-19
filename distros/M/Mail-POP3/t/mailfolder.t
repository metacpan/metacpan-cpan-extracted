use strict;
use Test::More tests => 12;

our %CONFIG;
do './t/testcommon.pl';

use File::Temp;

END {ok(0, 'loaded') unless $::loaded;}
use Mail::POP3;
$::loaded = 1;
ok(1, 'loaded');

my $fake_mbox = File::Temp->new;
print $fake_mbox $CONFIG{fake_mbox_text};
$fake_mbox->seek(0, Fcntl::SEEK_SET);
my $tmpdir = File::Temp->newdir;
ok(1, 'test env set up');

my $mailbox = Mail::POP3::Folder::mbox::parse_to_disk->new(
    'user',
    'password',
    $<,
    $(,
    $fake_mbox,
    '^From ',
    '^\\s*$',
    $tmpdir,
    0, # debug
);
ok($mailbox->lock_acquire, 'lock_acquire');

my $tmpfh = File::Temp->new;
$mailbox->uidl_list($tmpfh);
$tmpfh->seek(0, Fcntl::SEEK_SET);
my $list = join '', <$tmpfh>;
my $list_ref = <<EOF;
1 <$CONFIG{msgid1}>
2 <$CONFIG{msgid2}>
3 <$CONFIG{msgid3}>
.
EOF
$list_ref =~ s#\n#\015\012#g;
ok(
  ($list eq $list_ref and $mailbox->messages == 3 and $mailbox->octets == 1053),
  'uidl_list'
);

ok($mailbox->uidl(2) eq "<$CONFIG{msgid2}>", 'uidl');

$mailbox->delete(2);
$tmpfh = File::Temp->new;
$mailbox->uidl_list($tmpfh);
$tmpfh->seek(0, Fcntl::SEEK_SET);
$list = join '', <$tmpfh>;
$list_ref = <<EOF;
1 <$CONFIG{msgid1}>
3 <$CONFIG{msgid3}>
.
EOF
$list_ref =~ s#\n#\015\012#g;
ok(
  ($list eq $list_ref and $mailbox->messages == 2 and $mailbox->octets == 711),
  'delete'
);

$tmpfh = File::Temp->new;
$mailbox->top(3, $tmpfh, 2);
$tmpfh->seek(0, Fcntl::SEEK_SET);
my $top = join '', <$tmpfh>;
my $top_ref = $CONFIG{msg3topnofrom};
$top_ref =~ s#\n#\015\012#g;
ok($top eq $top_ref, 'top');

$tmpfh = File::Temp->new;
$mailbox->retrieve(3, $tmpfh);
$tmpfh->seek(0, Fcntl::SEEK_SET);
my $retrieve = join '', <$tmpfh>;
my $retrieve_ref = $CONFIG{msg3nofrom};
$retrieve_ref =~ s#\n#\015\012#g;
ok(($retrieve eq $retrieve_ref and $mailbox->octets(2) == 342), 'retr');

ok(!$mailbox->is_valid(2) and $mailbox->is_valid(3), 'is_valid');

$mailbox->reset;
ok($mailbox->is_valid(2) and $mailbox->is_valid(3), 'reset');
$mailbox->delete(2);

ok(($mailbox->is_deleted(2) and !$mailbox->is_deleted(3)), 'is_deleted');

$mailbox->flush_delete;
$mailbox->lock_release;
my $flush_ref = $CONFIG{msg1} . $CONFIG{msg3};
my $mb_content = join('', <$fake_mbox>);
$mb_content =~ s#\r$##gm; # for win32 - printing at starts puts \r in
ok($mb_content eq $flush_ref, 'flush_delete');
undef $fake_mbox;
undef $tmpdir;
