use strict;
use warnings;

use IO::Scalar;
use IO::ScalarArray;
use IO::Lines;
use Test::More tests => 6;

my $SH = IO::Scalar->new();
print $SH "Hi there!\n";
print $SH "Tres cool, no?\n";
is(${$SH->sref}, "Hi there!\nTres cool, no?\n", 'sref: Got the correct string');

$SH->seek(0, 0);
my $line = <$SH>;
is($line, "Hi there!\n", 'readline: got the right first line');

my $AH = IO::ScalarArray->new;
print $AH "Hi there!\n";
print $AH "Tres cool, no?\n";
is(join('', @{$AH->aref}), "Hi there!\nTres cool, no?\n", 'array aref: got the right contents');

$AH->seek(0, 0);
$line = <$AH>;
is($line, "Hi there!\n", 'array readline: got the right first line');

#------------------------------

my $LH = IO::Lines->new;
print $LH "Hi there!\n";
print $LH "Tres cool, no?\n";
is(join('', @{$LH->aref}), "Hi there!\nTres cool, no?\n", 'lines aref: got the right content');

$LH->seek(0, 0);
$line = <$LH>;
is($line, "Hi there!\n", 'lines readline: got the right first line');
