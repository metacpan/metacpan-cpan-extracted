#!perl -w
use strict;
use Test::More tests => 6;
use Email::LocalDelivery;

my $name = 't/test_mbox';
unlink $name;

my $mail = <<'MAIL';
To: foot@body
From: brane@body

From here I can see the pub.
It looks like a giant model pub.
MAIL

my @delivered = Email::LocalDelivery->deliver( $mail, $name );
is( scalar @delivered, 1, "just delivered to one mbox" );
is( $delivered[0], $name, "delivered to the right location" );
ok( -e $name, "file exists" );

use Symbol qw(gensym);
my $fh = gensym;
open $fh, $name or die "couldn't open $name: $!";
my $line = <$fh>;
like( $line, qr/^From /, "added a From_ line" );

ok( seek($fh, 0, 0), "rewound" );
my $count;
my @lines = grep { /^From / } <$fh>;
is( scalar @lines, 1, "Just the one From_ line" );
