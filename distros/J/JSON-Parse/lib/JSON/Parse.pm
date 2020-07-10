package JSON::Parse;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/
		   assert_valid_json
		   json_file_to_perl
		   json_to_perl
		   parse_json
		   parse_json_safe
		   valid_json
		   validate_json
	       /;

%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
our $VERSION = '0.57';
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

sub valid_json
{
    my ($json) = @_;
    if (! $json) {
	return 0;
    }
    eval {
	assert_valid_json (@_);
    };
    if ($@) {
	return 0;
    }
    return 1;
}

sub json_file_to_perl
{
    my ($file_name) = @_;
    my $json = '';
    open my $in, "<:encoding(utf8)", $file_name
        or croak "Error opening $file_name: $!";
    while (<$in>) {
	$json .= $_;
    }
    close $in or croak $!;
    return parse_json ($json);
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

1;
