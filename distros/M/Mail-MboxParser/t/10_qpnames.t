use Test;
use File::Spec;
use strict;

use Mail::MboxParser;
my $src = File::Spec->catfile('t', 'qpname');

BEGIN { plan tests => 1 };

my $mb = Mail::MboxParser->new($src);
my ($msg) = $mb->get_messages;

my $att = $msg->get_attachments;
skip(&Mail::MboxParser::Mail::HAVE_MIMEWORDS ? 0 : "Mime::Words not installed",
     defined $msg->get_attachments("test þðüýçö characters.txt"));



