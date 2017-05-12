#!env perl

use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 602;

use_ok('IPC::Transit') or exit;
use_ok('IPC::Transit::Test') or exit;

#clean out the queue if there's something in it
IPC::Transit::Test::clear_test_queue();

sub get_rand_string {
    my $num = shift;
    my $out = '';
    for (1..$num) {
        $out .= chr int rand 255;
    }
    return $out;
}

my $iteration = 100;
foreach my $serializer ('json', 'storable', 'dumper') {
    foreach my $ct (1..$iteration) {
        my $stuff = get_rand_string($ct);
        IPC::Transit::send(
            qname => $IPC::Transit::test_qname,
            message => { a => $stuff },
            serializer => $serializer,
            compression => 'none');
        ok my $ret = IPC::Transit::receive(qname => $IPC::Transit::test_qname);
        ok $ret->{a} eq $stuff;
    }
}
