#!/usr/bin/env perl

# Benchmark JSON::Create against JSON::XS.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Time::HiRes;
use Text::Table::Tiny 'generate_table';
use Getopt::Long;

my $ok = GetOptions (
    quicky => \my $quicky,
);

if (! $ok) {
    die;
}

# Just so I can use the latest versions

use lib '/home/ben/projects/json-create/blib/lib';
use lib '/home/ben/projects/json-create/blib/arch';

# Contenders

use JSON::Create 'create_json';
use JSON::XS ();
use Cpanel::JSON::XS ();

# Number of repetitions. No matter how large this is made, the results
# always vary wildly from run to run.

my $count = 1000;
my $times = 200;

if ($quicky) {
    $count = 100;
    $times = 20;
}

print "Versions used:\n";

my @modules = qw/Cpanel::JSON::XS JSON::XS JSON::Create/;
my @mvp;
for my $module (@modules) {
    my $abbrev = $module;
    $abbrev =~ s/(\w)\w+\W*/$1/g; 
    my $version = eval "\$${module}::VERSION";
    push @mvp, [$abbrev, $module, $version];
}
print generate_table (rows => \@mvp, separate_rows => 1);

my %these = (
    'JC' => 'JSON::Create::create_json ($stuff)',
    'JX' => 'JSON::XS::encode_json ($stuff)',
    'CJX' => 'Cpanel::JSON::XS::encode_json ($stuff)',
);

# ASCII string test

my $stuff = {
    captain => 'planet',
    he => "'s",
    a => 'hero',
    gonna => 'take',
    pollution => 'down',
    to => 'zero',
    "he's" => 'our',
    powers => 'magnified',
    and => "he's",
    fighting => 'on',
    the => "planet's",
    side => "Captain Planet!",
};

header ("hash of ASCII strings");

cmpthese ($stuff);

my $h2n = {
    a => 1,
    b => 2,
    c => 4,
    d => 8,
    e => 16,
    f => 32,
    g => 64,
    h => 128,
    i => 256,
    j => 512,
    k => 1024,
    l => 2048,
    m => 4096,
    n => 8192,
    o => 16384,
    p => 32768,
    q => 65536,
    r => 131_072,
    s => 262_144,
    t => 524_288,
    u => 1_048_576,
    v => 2_097_152,
    w => 4_194_304,
    x => 8_388_608,
    y => 16_777_216,
    z => 33_554_432,
    A => 67_108_864,
    B => 134_217_728,
    C => 268_435_456,
    D => 536_870_912,
    E => 1_073_741_824,
};

header ("hash of integers");

cmpthese ($h2n);

use utf8;

my %unihash = (
    'う' => '雨',
    'あ' => '亜',
    'い' => '井',
    'え' => '絵',
    'お' => '尾',
    'ば' => [
	qw/場 馬 羽 葉 刃/
    ],
);


header ("hash of Unicode strings");

cmpthese (\%unihash);

header ("array of floats");

my $floats = [1.0e-10, 0.1, 1.1, 9e9, 3.141592653,-1.0e-20,-9e19,];

cmpthese ($floats);

header ("array of ASCII strings");

my $json = [
    'Higgins',
    'TC',
    'Magnum',
    'Hawaii',
    'Higgins',
    'TC',
    'Magnum',
    'Hawaii',
    'Links to the netherworld',
    'Shakespeare',
    'ferrari',
    '1234567890',
    'Selleck',
    'The old Clifford estate',
    'I did make a point of going in the daytime',
    'You\'re supposed to be dead',
    'Are you the one that hit me?',
    'Any particular reason?',
    'Why didn\'t you just call the police?',
    'GOT TO YOU',
]; 

cmpthese ($json);

exit;

sub cmpthese
{
    my ($stuff) = @_;
    my $min = 1e99;
    my %min;
    my $worst;
    my @results;

    print "Repetitions: $count x $times = ", $count * $times, "\n";

    push @results, ["Module", "1/min", "min", "improve"];
    $worst = 0;
    for my $module (sort keys %these) {
	$min{$module} = $min;
	for (1..$times) {
	    my $t = bench ($these{$module}, $stuff);
	    if ($t < $min{$module}) {
		$min{$module} = $t;
	    }
	}
	if ($min{$module} > $worst) {
	    $worst = $min{$module};
	}
    }

    for my $module (sort keys %these) {
	my @nums = map {sprintf ("%g", $_)} $count/$min{$module}, $min{$module}, $worst / $min{$module};
	push @results, [$module, @nums];
    }
    print generate_table (rows => \@results, header_row => 1);
    print "\n";
}

sub bench
{
    my ($code, $stuff) = @_;

    my $cent = eval "sub { my \$t = Time::HiRes::time; " . (join ";", ($code) x $count) . "; Time::HiRes::time - \$t }";
    if ($@) {
	print "$@\n";
    }
    $cent->();
    my $t = $cent->();

    return $t;
}



sub header
{
    my ($head) = @_;
    print "\nComparing $head...\n\n";
}
