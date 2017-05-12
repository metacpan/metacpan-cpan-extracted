#!/usr/bin/perl -w
#
# Testing parser of BioMoby XML inputs.
#
# $Id: moses-testing-parser.pl,v 1.3 2008/02/21 00:12:55 kawas Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------

# some command-line options
use Getopt::Std;
use vars qw/ $opt_h $opt_d $opt_v $opt_n $opt_r $opt_b /;
getopt ('b');

# usage
if ($opt_h or @ARGV == 0) {
    print STDOUT <<'END_OF_USAGE';
Parsing of BioMoby XML inputs.
Usage: [-nrvd] [-b <input-name>:<known-type>] <XML-input-file>

    It also needs to get a location of a local cache (and potentially
    a BioMoby registry endpoint). It takes it from the
    'moby-service.cfg' configuration file.

    -b ... indicates a "backup" data type that is used when an
           unknown XML top-level tag is encountered
           (this is not usually needed at all - only when your
            data type definitions, the generated data types, are
            not up-to-date):

            Input data with article name <input-name>, if encoutered
            an uknown type, will use <known-type>.

    -n ... does not print the parsed result (by default it does)
    -r ... converts back (reverse) the parsed result into XML
           and prints it
    -v ... verbose
    -d ... debug
    -h ... help
END_OF_USAGE
    exit (0);
}
# -----------------------------------------------------------

use strict;

use MOSES::MOBY::Base;
use MOSES::MOBY::Parser;

$LOG->level ('INFO') if $opt_v;
$LOG->level ('DEBUG') if $opt_d;

my @parser_args = ();
if ($opt_b) {
    my ($input_name, $known_type) = split (/\s*:\s*/, $opt_b, 2);
    push (@parser_args, ( lowestKnownDataTypes => { $input_name => $known_type }));
}
my $parser = new MOSES::MOBY::Parser (@parser_args);
my $package = $parser->parse ( method => 'file', data => $ARGV[0] );

print $package unless $opt_n;
print $package->toXML->toString(1) if $opt_r;

__END__
