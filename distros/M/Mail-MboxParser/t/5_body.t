use Test;
use File::Spec;
use strict;

use Mail::MboxParser;

my $src = File::Spec->catfile('t', 'testbox');

BEGIN { plan tests => 18 };

my $mb    = Mail::MboxParser->new($src);
my @mails; 

for (0 .. $mb->nmsgs - 1) {
    push @mails, $mb->get_message($_);
}

# 1 - 8
print "Testing body-idx...\n";
for my $msg (@mails[0..7]) {
    ok($msg->find_body, 0);
}

# 9
print "Testing body-idx on multipart...\n";
ok($mails[8]->find_body, 1);

# 10 - 12
print "Signature for mail 1, 2, 9...\n";
for my $msg (@mails[0,1,8]) {
    ok($msg->body($msg->find_body)->signature);
}

# 13 - 18
print "No signature for mails 3, 4, 5, 6, 7, 8...\n";
for my $msg (@mails[2..7]) {
    my $body = $msg->body($msg->find_body);
    my @n = $body->signature;
    ok($body->error);
}
