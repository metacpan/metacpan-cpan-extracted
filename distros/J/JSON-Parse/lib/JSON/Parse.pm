package JSON::Parse;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
		   assert_valid_json
		   json_file_to_perl
		   json_to_perl
		   parse_json
		   parse_json_safe
		   read_json
		   valid_json
		   validate_json
	       /;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use Carp;
our $VERSION = '0.61';
require XSLoader;
XSLoader::load (__PACKAGE__, $VERSION);

# Experimental, return a string of JSON as the error.

our $json_diagnostics;

# JSON "null" value. Although we're now using PL_sv_yes and PL_sv_no,
# we don't use PL_sv_undef, because perldoc perlguts says it's a bad
# idea.

our $null;

sub parse_json_safe
{
    my $p;
    eval {
	$p = parse_json_safer (@_);
    };
    if ($@) {
	my $error = $@;
	if (ref $error eq 'HASH') {
	    my $error_as_string = $error->{"error as string"};
	    carp "JSON::Parse::parse_json_safe: $error_as_string";
	}
	else {
	    $error =~ s/at\s\S+\.pm\s+line\s+[0-9]+\.\s*$//;
	    carp "JSON::Parse::parse_json_safe: $error";
	}
	return undef;
    }
    return $p;
}

# Old names of subroutines.

sub json_to_perl
{
    goto &parse_json;
}

sub validate_json
{
    goto &assert_valid_json;
}

sub read_file
{
    my ($file_name) = @_;
    if (! -f $file_name) {
	# Trap possible errors from "open" before getting there.
	croak "File does not exist: '$file_name'";
    }
    my $json = '';
    open my $in, "<:encoding(utf8)", $file_name
        or croak "Error opening $file_name: $!";
    while (<$in>) {
	$json .= $_;
    }
    close $in or croak $!;
    return $json;
}

sub JSON::Parse::read
{
    my ($jp, $file_name) = @_;
    my $json = read_file ($file_name);
    return $jp->parse ($json);
}

sub read_json
{
    my ($file_name) = @_;
    my $json = read_file ($file_name);
    return parse_json ($json);
}

sub valid_json
{
    my ($json) = @_;
    if (! $json) {
	return 0;
    }
    my $ok = eval {
	assert_valid_json (@_);
	1;
    };
    return $ok;
}

sub json_file_to_perl
{
    goto &read_json;
}

sub run
{
    my ($parser, $json) = @_;
    if ($parser->get_warn_only ()) {
	my $out;
	eval {
	    $out = $parser->run_internal ($json);
	};
	if ($@) {
	    warn "$@";
	}
	return $out;
    }
    else {
	return $parser->run_internal ($json);
    }
}

sub parse
{
    goto &run;
}

1;
