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

our $VERSION = '0.06';

# Load the data from the file.

my $json = __FILE__;
$json =~ s!\.pm$!/abc.json!;
my $abc = json_file_to_perl ($json);

sub a2b
{
    my ($text, %options) = @_;
    my $oxford = $options{oxford};
    for my $e (@$abc) {
	if ($oxford && $e->{oxford}) {
	    # Skip spellings marked as Oxford.
	    next;
	}
	my $american = $e->{a};
	my $british = $e->{b};
	if ($e->{bam}) {
	    # The British spelling is ambiguous, e.g. metre/meter,
	    # programme/program.
	    $british .= "/$e->{a}";
	}
	$text =~ s/\b$american\b/$british/g;
    }
    return $text;
}

sub b2a
{
    my ($text) = @_;
    for my $e (@$abc) {
	my $american = $e->{a};
	my $british = $e->{b};
	if ($e->{aam}) {
	    $american .= "/$e->{b}";
	}
	$text =~ s/\b$british\b/$american/g;
    }
    return $text;
}

sub a2c
{
    my ($text) = @_;
    for my $e (@$abc) {
	if ($e->{ca} || $e->{o}) {
	    next;
	}
	my $american = $e->{a};
	my $canadian = $e->{b};
	if ($e->{bam}) {
	    $canadian .= "/$e->{a}";
	}
	$text =~ s/\b$american\b/$canadian/g;
    }
    return $text;
}

sub c2a
{
    my ($text) = @_;
    for my $e (@$abc) {
	if ($e->{oxford} || $e->{ca}) {
	    # Skip spellings marked as Oxford and spellings where
	    # Canadian is the same as American.
	    next;
	}
	my $american = $e->{a};
	my $canadian = $e->{b};
	if ($e->{bam}) {
	    # The British spelling is ambiguous, e.g. metre/meter,
	    # programme/program.
	    $canadian .= "/$e->{a}";
	}
	$text =~ s/\b$canadian\b/$american/g;
    }
    return $text;
}

sub c2b
{
    my ($text, %options) = @_;
    for my $e (@$abc) {
	if ($options{oxford} && $e->{oxford}) {
	    # Do not convert Oxford spellings.
	    next;
	}
	# Here we do not check the value of ca, but just convert any
	# American spellings which may be found in the Canadian text.
	my $canadian = $e->{a};
	my $british = $e->{b};
	$text =~ s/\b$canadian\b/$british/g;
    }
    return $text;
}

sub b2c
{
    my ($text) = @_;
    for my $e (@$abc) {
	if ($e->{ca}) {
	    # Convert the word if this is spelt differently in Canada
	    # and the UK.
	    my $canadian = $e->{a};
	    my $british = $e->{b};
	    $text =~ s/\b$british\b/$canadian/g;
	}
    }
    return $text;
}

1;
