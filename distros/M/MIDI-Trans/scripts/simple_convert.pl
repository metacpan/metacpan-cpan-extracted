#!/usr/local/bin/perl
#
# simple_convert.pl - C. Church (church@digitalkoma.com)
# A simple text->midi converter that operates
# on an input corpus composed of elements
# in form:
#
# <notename><oct>:<vol>
#
# e.g.: c1:100
#
# (c, lowest octave volume = 100)
#
# Leaving out an octave value
# uses the previously used octave.
#
# Usage:
#
# simple_convert.pl <input file> <output file> [<tempo> <event duration>]
#
# [<tempo> <event duration>] is optional, but the order
# is not.
#
# Try, for example:
# simple_convert.pl simple_input.txt out.mid 140 16
#
#------------------------------

use strict;
use warnings;

use MIDI::Trans;


my $infile = shift;
my $outfile = shift;
my $tempo = shift || 124;
my $duration = shift || 8;

my $last_oct = undef;

if(!defined($infile) || !defined($outfile)) {
	die("USAGE: simple_convert.pl <in file> <out file> [<tempo> <duration>]\n");
	}

if(! -r $infile) {
    die("ERROR: $infile is not readable!\n");
    }

    # create our note value / name map
    # using 11 octaves.
    
my %note_map = ();
my %name_map = ();
$name_map{1} = 'C';
$name_map{2} = 'C#';
$name_map{3} = 'D';
$name_map{4} = 'D#';
$name_map{5} = 'E';
$name_map{6} = 'F';
$name_map{7} = 'F#';
$name_map{8} = 'G';
$name_map{9} = 'G#';
$name_map{10} = 'A';
$name_map{11} = 'A#';
$name_map{12} = 'B';

my $note = 0;
my $oct = 1;

foreach (1..11) {
    $note_map{$oct} = ();
    foreach (1..12) {
        my $name = lc($name_map{$_});
        print("N: $name : $note : $oct\n");
        $note_map{$oct}{"$name"} = $note;
        $note++;
        last if($note > 127);
        }
    $oct++;
    }

print("$note_map{1}{c}\n");

    # create MIDI::Trans object
    
my $TransObj = MIDI::Trans->new( { 'Raise_Error' => 1 } );

    # run trans() method
    
if($TransObj->trans( { 'File' => $infile, 'Outfile' => $outfile,
                        'Tempo' => $tempo,
                        'Note' => \&note,
                        'Volume' => \&vol,
                        'Duration' => \&dur } )) {

    print("$infile Converted, Saved as $outfile; Tempo $tempo\n");
    exit(0);
    } else {
        my $errmsg = $TransObj->error();
        die("$errmsg\n");
        }
        

sub note {

 my $elem = lc(shift);
 my $pos = shift;

 return('rest') if($elem =~ /rest/i);

 my $value = $1 if($elem =~ /(.*?):.*/);

 return('rest') if(!defined($value));
 
 my($note,$oct);

    # parse out note given...
    
 if($value =~ /([a-f\#]+)(\d+)/) {
    $note = $1;
    $oct = $2;
    $last_oct = $oct;
    } elsif($value =~ /([a-f\#]+)/) {
        $note = $1;
        $oct = $last_oct;
        } else {
            return('rest');
            }
            
 return('rest') if(!defined($oct));

    # lookup the note in the map...
    
 my $out_note = $note_map{"$oct"}{"$note"};

 return('rest') if(!defined($out_note));
 
 return($out_note);
}

sub vol {

 my $elem = shift;
 my $pos = shift;
 
 my $value = $1 if($elem =~ /.*?:(\d+)/);
 
 return(0) if(!defined($value));
 
 return($value);
}

sub dur {

 my $elem = shift;
 my $pos = shift;

 return($duration);
}


 
