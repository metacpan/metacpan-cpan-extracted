#!/usr/bin/env perl
#
# Note: this version of the script is based on
# commit 8556bb4019b35a285ef7045a33431759b054ee60
# Date:   Sun Aug 3 15:29:58 2008 -0400
#
=head1 NAME

ged2xml.pl - convert GEDCOM files to MIT Simile Timeline XML

=head1 SYNOPSIS

ged2xml.pl [--force] [--xml] [-d5] gedcom_file

 Options:
   -re, --rel        Relationship type: ancestor by default or descendant
   -r, --root        Root person for the tree
   -o, --output      XML output file
   -f, --force       Do not prompt to confirm overwriting XML output file
   -d1, -d5          Set the debug level
   --man             Print the manual page
   -x, --xml         Print the xml to STDOUT

=head1 DESCRIPTION

MIT Simile Timeline ( http://simile.mit.edu/timeline ) loads an XML file containing titles and dates to create a horizontal AJAX timeline of events.  This script generates a compatible XML file from the birth and death dates in a GEDCOM file.

=head1 OPTIONS

=over 2

=item B<-d1, -d2, -d3, -d4, -d5>

Set the debug level.

=item B<-x, --xml>
Print the xml to STDOUT

=back

=head1 BUGS

 I need to at least pull years from unparseable birth dates.

=cut

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
Getopt::Long::Configure qw( auto_abbrev auto_version auto_help bundling );
use Readonly;
use List::MoreUtils qw( any );
use Data::Dumper;
# remove private debug module
#use PD::Debug qw( Debug DebugLevel $DEBUG_LEVEL $DEBUG_1 $DEBUG_2 $DEBUG_3 $DEBUG_4 $DEBUG_5 );
use Carp;
use Gedcom;
use Date::Manip;
use XML::Simple;

# used in PD::Debug
## if -zerocolor is given as an argument, disable ANSI color
#if ( any{ /^[-]+z/xmsi } @ARGV ) { $ENV{ANSI_COLORS_DISABLED} = 'yes' }

########################################################################
#
# OPTIONS

my( $HELP, $USAGE, $MAN, $XML, $FORCE, $ALL, $BLOOD_ONLY );

# some defaults
my $ROOT = 'Johann Sebastian Bach';
my $RELATIONSHIP = 'descendents';
my $GEDCOM = 'bach.ged';
my $XML_OUTPUTFILE = 'timeline.xml';

GetOptions(
    'root|r=s'   => \$ROOT, # the person at the root of the tree
    'rel|re=s'   => \$RELATIONSHIP, # ancestors or descendants of person
    'all|a'      => \$ALL, # show everyone in the tree
    'blood|b'    => \$BLOOD_ONLY, # blood relatives only
    'gedcom|g=s' => \$GEDCOM, # the GEDCOM file to parse
    'output|o=s' => \$XML_OUTPUTFILE,
    'force|f'    => \$FORCE,
#    'debug|d:+'  => \$DEBUG_LEVEL,
    'help|h'     => \$HELP,
    'usage|u'    => \$USAGE,
    'man'        => \$MAN,
    'zerocolor|z',
    'xml|x' =>\$XML
) or pod2usage(2);

if ( $HELP  ) { pod2usage(-verbose => 0); }
if ( $USAGE ) { pod2usage(-verbose => 1); }
if ( $MAN   ) { pod2usage(-verbose => 2); }

#Debug( "Debugging level $DEBUG_LEVEL enabled." );

#
########################################################################

########################################################################
# IMPORTANT VARIABLES
#
# XML data to be printed out
my $xml;

#
########################################################################

#my $gedcom_file = "bach.ged";
#DebugLevel( $DEBUG_1, "\$GEDCOM = $GEDCOM\n" );
my $gedcom_file = $GEDCOM;
#DebugLevel( $DEBUG_1, "\$gedcom_file = $gedcom_file\n" );
my $cb; # FIXME: what is this?  delete it?
Readonly my $GEDCOM_VERSION => '5.5';
my $ged = Gedcom->new(grammar_version => $GEDCOM_VERSION,
                      gedcom_file     => $gedcom_file,
                      read_only       => 1,
                      callback        => $cb);
#return unless $ged->validate;
if ( ! $ged->validate) { return };
#my $root = $ged->get_individual("Richard Francis Durbin");
my $root = $ged->get_individual($ROOT);
my $name = _clean_name($root->name);
#print "$name\n";
my $spouse_included;
if ( $BLOOD_ONLY ) {
    $spouse_included = "No";
}
else {
    $spouse_included = "Yes";
}
#DebugLevel( $DEBUG_1, "asked for $ROOT, got $name\n" );
print "The following options have been selected:\n";
print "  Person to start with:    $name\n";
print "  Relationships to list:   $RELATIONSHIP\n";
if ( $RELATIONSHIP eq 'descendents' ) {
    print "  Spouses included:        $spouse_included\n";
}
print "  GEDCOM source file:      $gedcom_file\n";
print "  XML output file:         $XML_OUTPUTFILE\n";
print "Use --help to see how to change these options\n";

my @people;

if ($ALL) {
    # get everyone in GEDCOM file
    print "printing all\n";
    @people = $ged->individuals;
}
else {
    # get people defined by relationship (ancestors, descendents, etc.)
    @people = $root->$RELATIONSHIP;
    my( @spouses, @siblings );
    if ( $RELATIONSHIP eq "descendents" && ! $BLOOD_ONLY ) {
        @spouses = get_spouses($root, @people);
    }
    # get the siblings of the person whose ancestors we want
    if ( $RELATIONSHIP eq "ancestors") {
        @siblings = $root->siblings;
    }
    @people = ($root, @people, @spouses, @siblings );
}

sub get_spouses {
    my @people = @_;
    my @spouses;
    for my $person ( @people ) {
        if ( $person->spouse ) {
            my $spouse = $person->spouse;
            #print $person->name, "\t ", $spouse->name, "\n";
            push( @spouses, $spouse );
        }
    }
    return @spouses;
}

$xml = "<data>\n";
my %seen;
my %notes;
my @missing;
my $missing_message = "The following people would have been included but we don't have a birth date for them: ";
for my $person (@people) {
    #print $person->name, "\n";
    my $name = $person->get_value('name');
    $seen{$person}++;
    if ( $seen{$person} > 1 ) {
        warn "WARNING: $name has already been seen, skipping";
        next;
    }
    #$name =~ s|/||g;
    $name = _clean_name($name);
    #DebugLevel( $DEBUG_1, "\$name = $name\n" );
    #($name) = $name =~ /(\w+)/;
    my $birth_date = $person->get_value('birth date');
    my $death_date = $person->get_value('death date');
    my $summary    = $person->summary;

    # is the date undef?
    # is the date parseable at all?  can we get the year out?
    my $rez = _parse_date($birth_date);
    my $extracted_date;
    # yes there's a birth date, yes, it's valid
    if ($rez) {
        #DebugLevel( $DEBUG_1, "$name birth date: $birth_date" );
        #DebugLevel( $DEBUG_2, "$rez $name" );
        $notes{$name} = ""; # to avoid uninitialized value error
    }
    #yes there's a birth date, no it isn't valid
    elsif ($birth_date) {
        #DebugLevel( $DEBUG_1, "BAD DATE: $summary\n" );
        # FIXME: do something with these notes
        $notes{$name} = "Fuzzy birthdate: $birth_date";
        ($extracted_date) = $birth_date =~ /(\d\d\d\d)/;
    }
    else {
        # skip this person if there is no valid date
        #warn "WARNING: skipping $name as there is no birth date";
        push(@missing, $name);
        next;
    }
    if ($extracted_date ) { $birth_date = $extracted_date; }
    $extracted_date = undef;
    my $valid_death_date = _parse_date($death_date);
    # begin hack for james riley durbin
    # his death date (FEB 1978) is parseable by ParseDate
    # but not by Similie Timeline.  so we'll force it to be
    # invalid so only the year is extracted.
    if ($name eq "James Riley Durbin") {
        warn "WARNING: James Riley Durbin death date hack";
        $valid_death_date = 0;
    }
    # end hack for james riley durbin
    if ( $death_date && ! $valid_death_date ) {
        ($extracted_date) = $death_date =~ /(\d\d\d\d)/;
    }
    if ($extracted_date ) { $death_date = $extracted_date; }

    my $event;
    if ($birth_date && $death_date) {
        my $start = "$birth_date";
        my $end = "$death_date";
        $event .= "<event title=\"$name\" start=\"$start\" end=\"$end\">$notes{$name}</event>\n";
    $xml .= "  $event";
    }
    elsif ($birth_date) {
        my $start = "$birth_date";
        $event .= "<event title=\"$name\" start=\"$start\">$notes{$name}</event>\n";
    $xml .= "  $event";
    }
    #$event .= "/>";
    #$xml .= "  $event\n";
    #$xml .= "  $event";
}
if (@missing) {
    my $today = UnixDate( ParseDate("today"),"%b %e %Y");
    for my $person ( @missing ) {
        $missing_message .= "$person, ";
    }
    chop $missing_message;
    chop $missing_message;
    $xml .= "  <event title=\"Missing\" start=\"$today\">$missing_message</event>\n";
}
$xml .= "</data>\n";
if ( $XML ) { print $xml; }
if (! $FORCE && -e $XML_OUTPUTFILE ) {
    my $answer = 'maybe';
    while ($answer ne 'y' && $answer ne 'n') {
        print "WARNING: Output file $XML_OUTPUTFILE exists.  Overwrite? (y/n): ";
        chomp( $answer = <STDIN>);
        if ($answer eq 'n') {
            print "Exiting.  No changes were made.\n";
            exit;
        }
    }
}
open my $fh, '>', "$XML_OUTPUTFILE" or croak "Couldn't open $XML_OUTPUTFILE: $!";
print {$fh} $xml;
close $fh or croak "Couldn't close $XML_OUTPUTFILE: $!";
print "MIT Simile Timeline XML data source created: $XML_OUTPUTFILE\n";

sub _clean_name {
    my($name) = @_;
    # find forward slashes (/, escaped) everwhere (/g) and remove them
    $name =~ s/\///xmsg;
    return $name;
}

sub _parse_date {
    my( $date )= @_;
    my $result = ParseDate( $date );
    return $result;
}
