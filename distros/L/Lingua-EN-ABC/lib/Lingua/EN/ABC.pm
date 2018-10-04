package Lingua::EN::ABC;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/a2b b2a a2c c2a b2c c2b/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
use JSON::Parse 'json_file_to_perl';
use Convert::Moji 'make_regex';

our $VERSION = '0.10';

# Load the data from the file.

my $json = __FILE__;
$json =~ s!\.pm$!/abc.json!;
my $abc = json_file_to_perl ($json);

# American
my @a;
my @as;
# British
my @b;
my @bs;
# Canadian
my @c;
my @cs;
# British Oxford
my @bo;
# Map from either American or British version to its entry
my %any2e;
for my $e (@$abc) {
    $any2e{$e->{a}} = $e;
    $any2e{$e->{b}} = $e;
    push @a, $e->{a};
    push @b, $e->{b};
    # co is "Canadian output".
    if ($e->{ca}) {
	$e->{co} = $e->{a};
    }
    else {
	$e->{co} = $e->{b};
    }
    # bo is "British Oxford".
    if ($e->{oxford}) {
	$e->{bo} = $e->{a};
    }
    else {
	$e->{bo} = $e->{b};
    }
    # ao is "American output".
    if ($e->{aam}) {
	$e->{ao} = "$e->{a}/$e->{b}";
    }
    else {
	$e->{ao} = $e->{a};
    }
}

for my $k (keys %any2e) {
    my $e = $any2e{$k};
    if ($e->{s} && ! ($e->{bam} || $e->{aam})) {
	push @as, $e->{a};
	push @bs, $e->{b};
    }
}

# Word-matching regexes

my $a_re = make_regex (@a);
my $b_re = make_regex (@b);
my $bo_re = make_regex (@bo);
my $as_re = make_regex (@as);
my $bs_re = make_regex (@bs);

sub a2b
{
    my ($text, %options) = @_;
    my $re = $a_re;
    my $out = 'b';
    if ($options{oxford}) {
	$out = 'bo';
    }
    if ($options{s}) {
	$re = $as_re;
    }
    $text =~ s/\b($re)(s?)\b/$any2e{$1}{$out}$3/g;
    return $text;
}

sub b2a
{
    my ($text, %options) = @_;
    my $re = $b_re;
    if ($options{s}) {
	$re = $bs_re;
    }
    $text =~ s/\b($re)(s?)\b/$any2e{$1}{ao}$3/g;
    return $text;
}

sub a2c
{
    my ($text, %options) = @_;
    my $re = $a_re;
    if ($options{s}) {
	$re = $as_re;
    }
    $text =~ s/\b($re)(s?)\b/$any2e{$1}{co}$3/g;
    return $text;
}

sub c2a
{
    my ($text, %options) = @_;
    my $re = $b_re;
    if ($options{s}) {
	$re = $bs_re;
    }
    $text =~ s/\b($re)(s?)\b/$any2e{$1}{ao}$3/g;
    return $text;
}

sub c2b
{
    my ($text, %options) = @_;
    my $type = 'b';
    if ($options{oxford}) {
	$type = 'bo';
    }
    my $re = $a_re;
    if ($options{s}) {
	$re = $as_re;
    }
    $text =~ s/\b($re)(s?)\b/$any2e{$1}{$type}$3/g;
    return $text;
}

sub b2c
{
    my ($text, %options) = @_;
    my $re = $b_re;
    if ($options{s}) {
	$re = $bs_re;
    }
    $text =~ s/\b($re)(s?)\b/$any2e{$1}{co}$3/g;
    return $text;
}

1;
