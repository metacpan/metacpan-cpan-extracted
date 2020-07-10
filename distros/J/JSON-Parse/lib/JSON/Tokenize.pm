package JSON::Tokenize;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
use JSON::Parse;
our @EXPORT_OK = qw/tokenize_json tokenize_start tokenize_next tokenize_start tokenize_end tokenize_type tokenize_child tokenize_text/;
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
use Carp;
our $VERSION = '0.57';

sub tokenize_text
{
    my ($input, $token) = @_;
    if (! $input || ! $token) {
	croak "tokenize_text requires input string and JSON::Tokenize object";
    }
    my $start = tokenize_start ($token);
    my $length = tokenize_end ($token) - $start;
    my $text;
    if (utf8::is_utf8 ($input)) {
	# $start and $length refer to bytes, so we need to convert
	# $input into bytes.
	my $copy = $input;
	utf8::encode ($copy);
	$text = substr ($copy, $start, $length);
	# Make the output utf8-flagged.
	utf8::decode ($text);
    }
    else {
	$text = substr ($input, $start, $length);
    }
    return $text;
}

1;
