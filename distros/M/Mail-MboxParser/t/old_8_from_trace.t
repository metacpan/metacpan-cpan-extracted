use Test;
use File::Spec;
use strict;

use Mail::MboxParser;

my $src = File::Spec->catfile('t', 'testbox');

BEGIN { plan tests => 9 };

my $mb    = Mail::MboxParser->new($src, oldparser => 1);
my @mails = $mb->get_messages;

# 1
print "Testing num of messages...\n";
ok(scalar @mails, $mb->nmsgs);

# 2 - 7
print "Testing from- and received-lines...\n";
ok($mails[0]->from_line, 
    'From friedrich@pythonpros.com  Thu Feb 26 17:23:40 1998');
ok(scalar $mails[0]->trace, 2);

ok($mails[1]->from_line,
    'From nobody@p11.speed-link.de Thu Jul 05 08:03:22 2001');
ok(scalar $mails[1]->trace, 6);

ok($mails[2]->from_line,
    'From nobody@p11.speed-link.de Thu Jul 05 08:03:22 2001');
ok(scalar $mails[2]->trace, 6);

# 8 - 9 ( for M::MP::M::get_field() )
print "Testing get_field() method...\n";
ok ($mails[0]->get_field('message-id'),
      'Message-ID: <34F5EB6C.4F37CD1E@pythonpros.com>');
ok ($mails[4]->get_field('to'),
      'To: Tassilo von Parseval <tassilo.parseval@post.rwth-aachen.de>, andreas.koenig@anima.de');
