use Test;
use File::Spec;
use strict;

use Mail::MboxParser;

my $src = File::Spec->catfile('t', 'testbox');

BEGIN { plan tests => 19 };

my $mb      = Mail::MboxParser->new($src, oldparser => 1);

# 1 - 9
my $c = 0;
for my $msg ($mb->get_messages) {
    if ($c == 8) {
        ok($msg->get_attachments('Plans'), 2);
    }
    else {
        ok ($msg->get_attachments, undef);
    }
    $c++;
}

# 10 - 18
$c = 0;
while (my $msg = $mb->next_message) {
    if ($c == 8) {
        ok($msg->get_attachments('Plans'), 2);
    }
    else {
        ok ($msg->get_attachments, undef);
    }
    $c++;
} 
    
# 19
ok($mb->get_message(8)->get_attachments('Plans'), 2);


