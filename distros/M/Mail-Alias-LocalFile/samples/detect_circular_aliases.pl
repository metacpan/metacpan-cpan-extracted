#!/usr/bin/env perl

use 5.36.0;

# uncomment if you have an older version of Perl
# use 5.010;
# use strict;
# use warnings;
# use feature 'say';

use YAML::XS qw(LoadFile);
use JSON::XS;
use Data::Dumper::Concise;
use Getopt::Long;
use File::Basename;

# use FindBin;  # path to this script
# use lib "$FindBin::Bin/../../../"; # path to lib directory
use Mail::Alias::LocalFile;

# Define default values
my $alias_file = 'aliases.yml';
my $format;
my $debug_mode = 0;
my $help       = 0;

# Parse command line options
GetOptions(
    "file|f=s"   => \$alias_file,
    "format|t=s" => \$format,
    "debug|d"    => \$debug_mode,
    "help|h"     => \$help
  )
  or die
  "Error in command line arguments\nTry '$0 --help' for more information.\n";

# Display help and exit if requested
if ($help) {
    print <<EOF;
Usage: $0 [options]

Options:
  --file, -f FILENAME    Path to the alias file to analyze (default: aliases.yml)
  --format -t FORMAT     Explicitly specify format: YAML or JSON
                         (default: auto-detect from file extension)
  --debug, -d            Enable debug output showing full alias expansion
  --help, -h             Display this help message

For more detailed information, run:
  perldoc $0
EOF
    exit 0;
}

die "File not found: $alias_file\n" unless -f $alias_file;

# Determine file format if not explicitly specified
if ( !$format ) {
    my ( $name, $path, $suffix ) = fileparse( $alias_file, qr/\.[^.]*/ );
    $suffix = lc( substr( $suffix, 1 ) )
      if $suffix;    # Remove leading dot and lowercase

    if ( $suffix =~ /^(ya?ml)$/i ) {
        $format = 'YAML';
    }
    elsif ( $suffix =~ /^(json|jsn)$/i ) {
        $format = 'JSON';
    }
    else {
        die
"Unable to determine file format from extension: $suffix\nPlease specify format using --format option.\n";
    }
}

# Normalize format to uppercase for case-insensitive comparison
$format = uc($format);

# Load the aliases file based on format
my $aliases;

if ( $format eq 'YAML' ) {
    eval { $aliases = LoadFile($alias_file); };
    if ($@) {
        die "Error parsing YAML file: $@\n";
    }
}
elsif ( $format eq 'JSON' ) {
    my $json_text;
    eval {
        local $/;    # Enable slurp mode
        open my $fh, '<', $alias_file or die "Cannot open $alias_file: $!\n";
        $json_text = <$fh>;
        close $fh;

        $aliases = JSON::XS->new->decode($json_text);
    };
    if ($@) {
        die "Error parsing JSON file: $@\n";
    }
}
else {
    die "Unsupported format: $format. Supported formats are YAML and JSON.\n";
}

say "Loaded aliases from $alias_file as $format format";

# Create a new resolver object - using Moose-style named parameters
my $resolver = Mail::Alias::LocalFile->new( aliases => $aliases );

# Detect and report circular references
my $circular_refs = $resolver->detect_circular_references($aliases);

if (@{$circular_refs}) {
    say "WARNING: Circular references detected:";
    foreach my $ref (@{$circular_refs}) {
        say "  $ref";
    }
}
else {
    say "No circular references detected.";
}

# Print full expansion of each alias for verification
# only if debug mode is enabled
if ($debug_mode) {
    say '';
    say "Full expansion of aliases:";
    foreach my $key ( sort keys %$aliases ) {
        say "$key:";
        my %seen = ();
        expand_alias( $key, $aliases, \%seen, 2 );
    }
}

# Function to expand aliases (for verification)
sub expand_alias {
    my ( $key, $aliases, $seen, $indent ) = @_;

    # Avoid infinite recursion
    if ( $seen->{$key} ) {
        say " " x $indent . "CIRCULAR: $key (already expanded)";
        return;
    }

    $seen->{$key} = 1;
    my $value = $aliases->{$key};

    if ( ref($value) eq 'ARRAY' ) {
        foreach my $item (@$value) {
            if ( ref($item) ) {

                # Handle nested arrays or hashes if needed
                print "  " x $indent . "Complex structure: " . Dumper($item);
            }
            else {
                expand_scalar_item( $item, $aliases, $seen, $indent );
            }
        }
    }
    elsif ( !ref($value) ) {
        expand_scalar_item( $value, $aliases, $seen, $indent );
    }
}

# Helper function to expand scalar items
sub expand_scalar_item {
    my ( $item, $aliases, $seen, $indent ) = @_;
    my @items = split( /,/, $item );
    foreach my $subitem (@items) {
        $subitem =~ s/^\s+|\s+$//g;    # Trim whitespace
        next unless $subitem;

        if ( exists $aliases->{$subitem} ) {
            say "  " x $indent . "$subitem:";
            expand_alias( $subitem, $aliases, $seen, $indent + 1 );
        }
        else {
            say "  " x $indent . "$subitem";
        }
    }
}

=head1 NAME

detect_circular_aliases.pl - Detect circular references in YAML or JSON alias files

=head1 SYNOPSIS

    perl detect_circular_aliases.pl [options]

    Options:
      --file=FILENAME -f   Path to the alias file to analyze (default: aliases.yml)
      --format=FORMAT -t   Explicitly specify format: YAML or JSON
                           (default: auto-detect from file extension)
      --debug         -d   Enable debug output showing full alias expansion
      --help          -h   Display usage information

    detect_circular_aliases.pl  [-h] [-d] -f /some/path/to/aliases.yml [-t YAML or JSON]

=head1 DESCRIPTION

This script analyzes YAML or JSON alias files to identify circular references between aliases.
It detects situations where alias A references alias B, which in turn references
back to alias A, either directly or through a chain of other aliases.

The script handles various formats of alias definitions including:
 - Direct string references
 - Comma-separated lists
 - Array entries
 - Nested references

=head1 ARGUMENTS

=over 4

=item B<--file=FILENAME> or B<-f FILENAME>

Path to the alias file to analyze. Defaults to 'aliases.yml' if not specified.

=item B<--format=FORMAT> or B<-t FORMAT>

Explicitly specify the file format as either 'YAML' or 'JSON'. 
If not specified, the format is auto-detected from the file extension:

 - '.yml', '.yaml', or '.YAML' for YAML format
 - '.json', '.jsn', or '.JSON' for JSON format

=item B<--debug> or B<-d>

Enable debug output to print the full expansion of each alias for verification 
and troubleshooting purposes.

=item B<--help> or B<-h>

Display usage information and exit.

=back

=head1 OUTPUT

The script outputs:

    1. Warnings for any detected circular references, showing the complete path
    2. With the --debug flag, also prints the full expansion of each alias for
       verification and troubleshooting purposes.

=head1 EXAMPLE

For a YAML file with:

    Jill: Jill@example.com, VP
    VP: Jill
    tech_team:
      - john@company.com, mary
      - dev_leads
    dev_leads:
      - sarah@company.com
      - tech_team

Or a JSON file with:

    {
        "Jill": "Jill@example.com, VP",
        "VP": "Jill",
        "tech_team": [
            "john@company.com, mary",
            "dev_leads"
        ],
        "dev_leads": [
            "sarah@company.com",
            "tech_team"
        ]
    }

The script will detect and report:
    WARNING: Circular references detected:
      Jill -> VP -> Jill
      tech_team -> dev_leads -> tech_team

=head1 INTERNAL FUNCTIONS

=over 4

=item B<detect_circular_references($aliases)>

Main entry point for circular reference detection. Takes a hash reference of
aliases and returns an array of paths representing circular references.

=item B<check_circular($key, $aliases, $path, $seen_paths, $circular_references)>

Recursive function that follows alias references, tracking the path to detect
circular references.

=item B<process_item($item, $aliases, $path, $seen_paths, $circular_references)>

Processes individual items within alias values, handling comma-separated values
and recursively checking for circular references.

=item B<expand_alias($key, $aliases, $seen, $indent)>

Expands an alias for verification purposes, showing the full hierarchy of values.

=item B<expand_scalar_item($item, $aliases, $seen, $indent)>

Helper function to expand scalar items within alias values.

=back

=head1 LIMITATIONS

The script does not handle complex structures beyond arrays and scalars.
Hash references within alias values would require additional processing logic.
That does not seem to be needed in practical use.

The script assumes the file holds email alias definitions. Single line values are stored as string entries.
Multi-line alias values are stored as arrays.

This script is presented to demonstrate how to use Mail::Alias::LocalFile

=head1 AUTHOR
Russ Brewer (RBREW)

Created on March 3, 2025

=cut
