#!/usr/bin/perl

# Author          : Johan Vromans
# Created On      : Sun Mar 10 18:02:02 2024
# Last Modified By: 
# Last Modified On: Wed May 15 12:45:20 2024
# Update Count    : 93
# Status          : Unknown, Use with caution!

################ Common stuff ################

use v5.26;
use feature 'signatures';
no warnings 'experimental::signatures';

# Package name.
my $my_package = 'JSON::Relaxed';
# Program name and version.
my ($my_name, $my_version) = qw( rrjson 0.02 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $mode = "rrjson";
my $execute;			# direct JSON from command line

# Parser options.
my $strict;
my $pretty = 1;
my $prp;
my $combined_keys;
my $implied_outer_hash;
my $croak_on_error;
my $extra_tokens_ok;

my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $pretoks = 0;
my $tokens = 0;
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

################ The Process ################

use FindBin;
use lib "$FindBin::Bin/../lib";
use JSON::Relaxed;
use File::LoadLines;
use Encode qw(decode_utf8);
binmode STDOUT => ':utf8';
binmode STDERR => ':utf8';

my $parser = JSON::Relaxed::Parser->new
  ( defined($strict) ? ( strict => $strict ) : (),
    defined($prp) ? ( prp => $prp ) : (),
    defined($combined_keys) ? ( combined_keys => $combined_keys ) : (),
    defined($implied_outer_hash) ? ( implied_outer_hash => $implied_outer_hash ) : (),
    defined($croak_on_error) ? ( croak_on_error => $croak_on_error ) : (),
    defined($extra_tokens_ok) ? ( extra_tokens_ok => $extra_tokens_ok ) : (),
    defined($prp) ? ( prp => $prp ) : (),
    defined($pretty) ? ( pretty => $pretty ) : (),
    booleans => 1,				# force default
    );

if ( $verbose > 1 ) {
    my @opts;
    for ( qw( strict pretty prp combined_keys implied_outer_hash croak_on_error extra_tokens_ok booleans ) ) {
	push( @opts, $_ ) if $parser->$_;
    }
    if ( @opts ) {
	warn( "Parser options: ", join(", ", @opts), ".\n");
    }

}

for my $file ( @ARGV ) {

    my $json;
    if ( $execute ) {
	$json = decode_utf8($file);
    }
    else {
	my $opts = { split => 0, fail => "soft" };
	$json = loadlines( $file, $opts );
	die( "$file: $opts->{error}\n") if $opts->{error};
    }

    my $data;
    if ( $pretoks || $tokens ) {
	$parser->croak_on_error = 0;
	$parser->data = $json;
	$parser->pretokenize;
	if ( $pretoks ) {
	    my $pretoks = $parser->pretoks;
	    dumper( $pretoks, as => "Pretoks" );
	}
	$parser->tokenize;
	if ( $tokens && !$parser->is_error ) {
	    my $tokens = $parser->tokens;
	    dumper( $tokens, as => "Tokens" );
	}
	$data = $parser->structure unless $parser->is_error;
    }
    else {
	$data = $parser->decode($json);
    }

    if ( $parser->is_error ) {
	warn( $execute ? "$file: JSON error: " : "",
	      "[", $parser->err_id, "] ", $parser->err_msg, "\n" );
	next;
    }

    if ( $mode eq "dump" || $mode eq "dumper" ) {
	dumper($data);
    }

    elsif ( $mode eq "rrjson" ) {
	print $parser->encode( data => $data );
	print "\n" unless $pretty;
    }
    elsif ( $mode eq "json_xs" ) {
	require JSON::XS;
	print ( JSON::XS->new->canonical->utf8(0)->pretty($pretty)->encode($data) );
    }

    else {			# default JSON
	require JSON::PP;
	print ( JSON::PP->new->canonical->utf8(0)->pretty($pretty)
		->boolean_values([JSON::Boolean->new(from=>"false"),
				  JSON::Boolean->new(from=>"true")])
		->convert_blessed->encode($data) );
    }
}

################ Subroutines ################

sub dumper($data, %opts) {
    if ( $mode eq "dump" || %opts ) {
	my %opts = ( %opts );
	require Data::Printer;
	if ( -t STDOUT ) {
	    Data::Printer::p( $data, %opts );
	}
	else {
	    print( Data::Printer::np( $data, %opts ) );
	}
    }

    elsif ( $mode eq "dumper" ) {
	local $Data::Dumper::Sortkeys  = 1;
	local $Data::Dumper::Indent    = 1;
	local $Data::Dumper::Quotekeys = 0;
	local $Data::Dumper::Deparse   = 1;
	local $Data::Dumper::Terse     = 1;
	local $Data::Dumper::Trailingcomma = 1;
	local $Data::Dumper::Useperl = 1;
	local $Data::Dumper::Useqq     = 0; # I want unicode visible
	require Data::Dumper;
	print( Data::Dumper->Dump( [$data] ) );
    }
}

################ Subroutines ################

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    if ( !GetOptions(
		     'rrjson'		    => sub { $mode = "rrjson" },
		     'json|json_pp'	    => sub { $mode = "json" },
		     'json_xs'		    => sub { $mode = "json_xs" },
		     'dump'		    => sub { $mode = "dump" },
		     'dumper'		    => sub { $mode = "dumper" },
		     'execute|e'	    => \$execute,
		     'strict!'		    => \$strict,
		     'prp!'		    => \$prp,
		     'combined_keys!'	    => \$combined_keys,
		     'implied_outer_hash!'  => \$implied_outer_hash,
		     'croak_on_error!'	    => \$croak_on_error,
		     'extra_tokens_ok!'	    => \$extra_tokens_ok,
		     'pretty!'		    => \$pretty,
		     'pretoks+'		    => \$pretoks,
		     'tokens+'		    => \$tokens,
		     'ident'		    => \$ident,
		     'verbose+'		    => \$verbose,
		     'quiet'		    => sub { $verbose = 0 },
		     'trace'		    => \$trace,
		     'help|?'		    => \$help,
		     'debug'		    => \$debug,
		    ) or $help)
    {
	app_usage(2);
    }
    app_ident() if $ident;
    app_usage(2) unless @ARGV;
}

sub app_ident() {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
    print STDERR ("JSON::Relaxed version $JSON::Relaxed::VERSION\n");
}

sub app_usage( $exit ) {
    app_ident();
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
  Inputs
   --execute -e		args are JSON, not filenames
  Output modes
   --rrjson		pretty printed RRJSON output (default)
   --json		JSON output (default)
   --json_xs		JSON_XS output
   --no-pretty		compact (non-pretty) output
   --dump		dump structure (Data::Printer)
   --dumper		dump structure (Data::Dumper)
  Parser options
   --strict		see the docs
   --prp                see the docs
   --implied_outer_hash see the docs
   --croak_on_error     see the docs
   --extra_tokens_ok    see the docs
  Miscellaneous
   --ident		shows identification
   --help		shows a brief help message and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible
EndOfUsage
    exit $exit if defined $exit && $exit != 0;
}
