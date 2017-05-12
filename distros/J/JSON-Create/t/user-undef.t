use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use JSON::Create;

# JCUT = Json Create Undef Test

{
    my $jcutwarning;
    my $jcutcalled;
    my $type_handler = sub {
	$jcutcalled = 1;
	return undef;
    };
    my $jcut = JSON::Create->new ();
    $jcut->type_handler ($type_handler);
    my $thing = {
	monkey => sub { print 'hello world'; },
    };
    local $SIG{__WARN__} = sub {
	$jcutwarning = "@_";
    };
    my $thingout = $jcut->run ($thing);
    ok (! defined $thingout, "got undefined value after bad sub call");
    ok ($jcutcalled, "called the bad subroutine");
    rightwarning ($jcutwarning);

    # Test with object handlers.

    # Mock object
    package Monkey::Shines;
    sub new
    {
	return bless {};
    }
    1;
    package main;
    $jcutwarning = undef;
    $jcutcalled = undef;
    my $jcut2 = JSON::Create->new ();
    $jcut2->obj ('Monkey::Shines' => sub {
		     $jcutcalled = 1;
		     return undef;
		 });
    my $thing2 = [
	Monkey::Shines->new (),
    ];
    ok (! $jcutcalled, "Pre-test setup of called flag");
    ok (! $jcutwarning, "Pre-test setup of warning flag");
    my $thing2out = $jcut2->run ($thing2);
    ok (! defined $thing2out, "got undefined value after bad sub call");
    ok ($jcutcalled, "called the bad subroutine");
    rightwarning ($jcutwarning);

    # Test with an object handler.

    $jcutwarning = undef;
    $jcutcalled = undef;
    my $jcut3 = JSON::Create->new ();
    $jcut3->obj_handler (sub {
			     $jcutcalled = 1;
			     return undef;
			 });
    my $thing3 = {
	flatulent => Monkey::Shines->new (),
    };
    ok (! $jcutcalled, "Pre-test setup of called flag");
    ok (! $jcutwarning, "Pre-test setup of warning flag");
    my $thing3out = $jcut3->run ($thing3);
    ok (! defined $thing3out, "got undefined value after bad sub call");
    ok ($jcutcalled, "called the bad subroutine");
    ok ($jcutwarning, "got a warning");
    if ($jcutwarning) {
	note ($jcutwarning);
    }
    rightwarning ($jcutwarning);
};

done_testing ();

sub rightwarning
{
    my ($warning) = @_;
    ok ($warning, "got a warning");
    if ($warning) {
	note ($warning);
    }
    like ($warning, qr/undefined value from user routine/i,
	  "warning looks ok");
    unlike ($warning, qr/Use of uninitialized value/,
	    "Did not get Perl's warning");
}

