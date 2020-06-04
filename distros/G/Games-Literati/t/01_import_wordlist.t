#!/usr/bin/perl
########################################################################
# import_wordlist.t:
#	* import the default $WordFile="wordlist", with 21 words,
#           but 2 words are only one letter long, so they are ignored
#       * import same $WordFile, but allowing 1-letter words via
#           $MinimumWordLength=1 configuration
#       * import short $WordFile="wordlist2" with 2 valid words
########################################################################

use 5.008;

use warnings;
use strict;
use Test::More tests => 3;

use File::Basename qw/dirname/;
use Cwd qw/abs_path chdir/;
my $scdir = dirname($0);
#print STDERR "scdir = $scdir\n";
chdir($scdir);
#print $ENV{PWD}."\n";

use Games::Literati 0.040;
my $wordlistLength = 0;
my $expect;

#   TEST1: default './wordlist'; count the number of words imported
Games::Literati::var_init();                                   # call routine to force import of wordlist
$wordlistLength = scalar(keys %{Games::Literati::valid});       # count number of words in resultant array
$expect = 20;
is( $wordlistLength, $expect , "import default '$Games::Literati::WordFile'; expect $expect, got $wordlistLength");

#   TEST2: allow 1-letter words
$Games::Literati::MinimumWordLength = 1;
Games::Literati::var_init();                                   # call routine to force import of wordlist
$wordlistLength = scalar(keys %{Games::Literati::valid});       # count number of words in resultant array
$expect = 22;
is( $wordlistLength, $expect , "import default '$Games::Literati::WordFile'; expect $expect, got $wordlistLength");

#   TEST3: change $WordFile; count the number of words imported (different length file)
$Games::Literati::MinimumWordLength = 2;    # back to default word length limit
$Games::Literati::WordFile = './wordlist.2';
%{Games::Literati::valid} = (); # clear valid list
undef $Games::Literati::words;  # clear word-length \array
Games::Literati::var_init();                                   # call routine to force import of wordlist
$wordlistLength = scalar(keys %{Games::Literati::valid});       # count number of words in resultant array
$expect = 2;
is( $wordlistLength, $expect , "import changed '$Games::Literati::WordFile'; expect $expect, got $wordlistLength");

1;
