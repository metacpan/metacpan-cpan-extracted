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

our $VERSION = '0.07';

# Load the data from the file.

my $json = __FILE__;
$json =~ s!\.pm$!/abc.json!;
my $abc = json_file_to_perl ($json);

# American
my @a;
# British
my @b;
# Canadian
my @c;
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

# Word-matching regexes

my $a_re = make_regex (@a);
my $b_re = make_regex (@b);
my $c_re = make_regex (@c);
my $bo_re = make_regex (@bo);

sub a2b
{
    my ($text, %options) = @_;
    my $oxford = $options{oxford};
    if ($oxford) {
	$text =~ s/\b($a_re)\b/$any2e{$1}{bo}/g;
    }
    else {
	$text =~ s/\b($a_re)\b/$any2e{$1}{b}/g;
    }
    return $text;
}

sub b2a
{
    my ($text) = @_;
    $text =~ s/\b($b_re)\b/$any2e{$1}{ao}/g;
    return $text;
}

sub a2c
{
    my ($text) = @_;
    $text =~ s/\b($a_re)\b/$any2e{$1}{co}/g;
    return $text;
}

sub c2a
{
    my ($text) = @_;
    $text =~ s/\b($b_re)\b/$any2e{$1}{ao}/g;
    return $text;
}

sub c2b
{
    my ($text, %options) = @_;
    my $type = 'b';
    if ($options{oxford}) {
	$type = 'bo';
    }
    $text =~ s/\b($a_re)\b/$any2e{$1}{$type}/g;
    return $text;
}

sub b2c
{
    my ($text) = @_;
    $text =~ s/\b($b_re)\b/$any2e{$1}{co}/g;
    return $text;
}

1;
