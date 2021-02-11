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

package JSON::Free;
sub new {
    return bless {};
}
1;

package Zilog::Z80;
sub new
{
    return bless {};
}
1;
package Zilog::Z80::Buggles;
sub true {
    my $one = 1;
    return bless \$one;
}
1;
package main;

my $jc = JSON::Create->new ();
my $zilog = Zilog::Z80->new ();
my $thing = {
    zilog => $zilog,
};

# Test the vanilla behaviour with no funky objects.

my $outnoobj = $jc->create ($thing);
like ($outnoobj, qr/"zilog":\{\}/);

# Now we're going to funky on down with some funky objects.

$jc->obj (
    'Zilog::Z80' => sub {
	my ($obj) = @_;
	#print "$obj\n";
	if ($obj->{jive}) {
	    return "\"$obj->{jive}\"";
	}
	else {
	    return '"passive-aggressive-programmer"';
	}
    },
    'JSON::Free' => sub {
	my ($self) = @_;
	# The nature of monkey was ... irrepressible
	return '"A knife cannot cut itself"',
    },
);
my $outobj = $jc->create ($thing);
like ($outobj, qr/"zilog":"passive-aggressive-programmer"/);
note ($outobj);

# Test setting a value in our object and retrieving it via the JSON.

# Give me that jive Clive.
$zilog->{jive} = 'clive';
my $outobjvalue = $jc->create ($thing);
like ($outobjvalue, qr/"zilog":"clive"/);
note ($outobjvalue);

# Same thing as above.
my $jf = JSON::Free->new ();
my $selfjson = $jc->create ({self => $jf});
like ($selfjson, qr/"self":"A knife cannot cut itself"/);
note ($selfjson);

# Check the interplay of bool and obj routines.

$jc->bool ('Zilog::Z80::Buggles');
my $buggles = Zilog::Z80::Buggles::true;
my $monkey = {
    masako => $zilog,
    yoshiyuki => $buggles,
};
my $outbool = $jc->create ($monkey);
like ($outbool, qr/"yoshiyuki":true/);
# If it comes out like jive:clive, we've deleted the object handler.
like ($outbool, qr/"masako":"clive"/);
note ($outbool);
# Test inserting the bool first, then the obj.
my $newjc = JSON::Create->new ();
$newjc->bool ('Zilog::Z80::Buggles');
$newjc->obj (
    'Zilog::Z80' => sub {
	my ($obj) = @_;
	#	    print "$obj\n";
	if ($obj->{jive}) {
	    return "\"$obj->{jive}\"";
	}
	else {
	    return '"passive-aggressive-programmer"';
	}
    },
);
my $outbool2 = $newjc->create ($monkey);
like ($outbool2, qr/"yoshiyuki":true/, "boolean handler OK");
# If it comes out like jive:clive, we've deleted the object handler.
like ($outbool2, qr/"masako":"clive"/, "object handler OK");

$newjc->validate (1);
$newjc->fatal_errors (1);
eval {
    my $outbool3 = $newjc->create ($monkey);
};
ok (! $@, "no errors in user-generated JSON");
note ($@);
$newjc->fatal_errors (0);

package Masako::Natsume;
sub new { return bless {}; }
sub to_json { return 'this is not valid JSON'; }
1;
package main;
my $mn = Masako::Natsume->new ();
$newjc->obj ('Masako::Natsume' => \&Masako::Natsume::to_json);
my $warning;
$SIG{__WARN__} = sub {$warning = "@_";};
my $mnj = $newjc->create ({tripitaka => $mn});
ok (! defined $mnj, "Undefined return value with bad routine");
note ($mnj);
ok ($warning, "Got warning with invalid JSON");
note ($warning);

TODO: {
    local $TODO = 'Combine boolean and obj';
};

done_testing ();
