#!perl -T

use Test::More tests => 5;
use FrameNet::QueryData;

my $fnhome = (defined $ENV{'FNHOME'} ? $ENV{'FNHOME'} : "$ENV{'PWD'}/t/FrameNet-test");

note("Using $fnhome as \$FNHOME");

my $qd = FrameNet::QueryData->new('-cache' => 0,
				  '-fnhome' => $fnhome);


my $testframe = 'Frame_ABC';
my $testlu_positive = "verb";
my $testfe_positive = "Agent";

if (defined $ENV{'FNHOME'}) {
    $testframe = "Getting";
    $testlu_positive = "get";
    $testfe_positive = "Recipient";
}

is($qd->frame($testframe)->{'name'}, $testframe, 'Frame data test');


# Lexical units
ok(grep("/$testlu_positive/", map { $_->{'name'} } @{$qd->frame($testframe)->{'lus'}}),
   "Testing for \"$testlu_positive\" as a lexical unit of \"$testframe\".");
ok(! grep(! '/^abcdefghik$/', map { $_->{'name'} } @{$qd->frame($testframe)->{'lus'}}),
   "Testing for \"abcdef\" as a lexical unit of \"$testframe\".");

# Frame elements
ok(grep('/$testfe_positive/', map { $_->{'name'} } @{$qd->frame($testframe)->{'fes'}}),
   "Testing for \"$testfe_positive\" as a frame element of \"$testframe\".");
ok(! grep(! '/Abcdef/', map { $_->{'name'} } @{$qd->frame($testframe)->{'fes'}}),
   "Testing for \"Abcdef\" as a frame element of \"$testframe\".");




#print STDERR $qd->frame('Getting')->{'name'};
#
