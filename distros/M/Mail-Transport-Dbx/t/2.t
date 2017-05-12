use Test;
use File::Spec;

BEGIN { plan tests => 26 };

use Mail::Transport::Dbx;

ok(1); # If we made it this far, we're ok.

my $dbx = eval {
    Mail::Transport::Dbx->new(File::Spec->catfile("t", "test.dbx"));
};

ok(!$@);
ok($dbx);
ok($dbx->msgcount, 1);
ok($dbx->errstr, "No error");

my $item = $dbx->get(0);

ok($dbx->errstr, "No error");
ok($item);
ok($item->isa("Mail::Transport::Dbx::Email"));
ok($item->as_string);
ok($item->subject, "Please read you won't be sorry........");
ok($item->psubject, $item->subject);
ok($item->msgid, '<200204140027.g3E0RlgZ025299@ue250-1.rz.RWTH-Aachen.DE>');
ok($item->parents_ids, undef);
ok($item->sender_name, "Wealth_Enterprises_2002");
ok($item->sender_address, 'off_1@webstation.com');
ok($item->recip_name, 'tassilo.parseval@post.rwth-aachen.de');
ok($item->recip_address, '<tassilo.parseval@post.rwth-aachen.de>');
ok($item->oe_account_name, "pbox.dialup.rwth-aachen.de");
ok($item->oe_account_num, "00000001");
ok($item->fetched_server, "pbox.dialup.rwth-aachen.de");
ok($item->rcvd_gmtime, "Sun Apr 14 00:27:57 2002");
ok($item->date_received);
ok($item->is_seen);
ok($item->is_email);
ok($item->is_folder, 0);

$dbx->get(1);
ok($dbx->errstr, "Index out of range");
