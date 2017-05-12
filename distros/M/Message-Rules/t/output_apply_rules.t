#!env perl

use strict;use warnings;

use lib '../lib';
use Test::More;
use JSON;

use_ok('Message::Rules');

ok my $r = Message::Rules->new();

ok $r->load_rules_from_directory('t/conf');
system 'rm -rf /tmp/message-rules';
mkdir '/tmp/message-rules';
ok $r->output_apply_rules('t/incoming', '/tmp/message-rules');
my $message;
{   my $path = '/tmp/message-rules/one';
    ok -r $path;
    open my $fh, '<', $path;
    my $contents;
    read $fh, $contents, 1024;
    close $fh;
    ok $message = decode_json $contents;
}
ok $message->{main} eq 'thing';
ok $message->{this} eq 'that';

ok 1;

done_testing();
system 'rm -rf /tmp/message-rules';
