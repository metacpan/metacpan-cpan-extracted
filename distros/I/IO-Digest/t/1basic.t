#!/usr/bin/perl -w
use Test::More tests => 3;
use IO::Digest;

my $digest = IO::Digest->new (\*STDOUT, 'MD5');

print "fsck\n";
is ($digest->hexdigest, 'b4fd7568bef9cde663dee6e029bf04ec');

print "fsck\nfsck\n";
is ($digest->hexdigest, 'cde05cba57ea689e1dd96304759d0184');

eval {
$digest = IO::Digest->new (\*STDOUT, 'CLKAO'); # I don't think there will be Digest::CLKAO
};
ok ($@);
