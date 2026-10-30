use strict;
use warnings;
use Test::More tests => 4;

use MIME::Parser;

sub flat {
    my ($n) = @_;
    return "Content-Type: multipart/mixed; boundary=b\n\n"
         . "--b\nContent-Type: text/plain\n\nhello\n" x $n . "--b--\n";
}

sub nested {
    my ($n) = @_;
    my $msg = '';
    $msg .= "Content-Type: multipart/mixed; boundary=b$_\n\n--b$_\n" for 1 .. $n;
    $msg .= "Content-Type: text/plain\n\nhello\n";
    $msg .= "--b$_--\n" for reverse 1 .. $n;
    return $msg;
}

my $parser = MIME::Parser->new();
$parser->output_to_core(1);
ok($parser->parse_data(flat(999)), 'Message with 1000 parts is parsed');
ok(!$parser->parse_data(flat(1000)), 'Message with 1001 parts is refused by default');
ok($parser->parse_data(nested(64)), 'Message nested 64 deep is parsed');
ok(!$parser->parse_data(nested(65)), 'Message nested 65 deep is refused by default');
