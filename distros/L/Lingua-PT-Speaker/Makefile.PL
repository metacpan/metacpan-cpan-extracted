use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::AutoConf;

# Check for PT1 phonemes path..........................

my @pt1paths = qw!/usr/lib/mbrola/pt1/pt1
		  /usr/lib/pt1/pt1
		  /usr/local/lib/mbrola/pt1/pt1
		  /usr/local/lib/pt1/pt1!;

my $PT1 = undef;
for my $pt1path (@pt1paths) {
  $PT1 = $pt1path if -f $pt1path && -r $pt1path;
}

if ($PT1) {
  print "Found PT1 phonemes at '$PT1'.\n";
} else {
  my $path = prompt("Did not found PT1 phonemes. Please enter full path:");

  if (($path eq "skip") || (-f $path && -r $path)) {
    $PT1 = $path;
  } else {
    print "Did not found PT1 phonemes in supplied path.\n";
    print "You can get the PT1 phonemes library at mbrola homepage.\n";
    exit(1);
  }
}

my $quotedpath = quotemeta($PT1);

# Find for player.......................................

my $player = inc::AutoConf->check_progs(qw/play sndplay esdplay rawplay/);
if ($player) {
  print "Using '$player' for sound output.\n";
} else {
  print "Didn't find a suitable player for sound output.\n'";
  print "Searched for 'play', 'sndplay', 'esdplay' and 'rawplay'.\n";
  print "You may need to use the command line switch to choose the correct player.\n";
}

my $quotedplayer = quotemeta($player);

# Find mbrola.................................

my $mbrola = inc::AutoConf->check_progs(qw/mbrola/);

if ($mbrola) {
  print "Using '$mbrola' command.\n";
} else {
  print "Didn't find mbrola. Download it from\n";
  print "http://tcts.fpms.ac.be/synthesis/mbrola.html\n";
  print "and add it to your PATH as 'mbrola'\n";
  $mbrola = 'mbrola';
  #exit 1;
}

my $quotedmbrola = quotemeta($mbrola);

# Rewrite pt-speak command line tool....................

`perl -e 'while(<>) { s/##PLAYER##/$quotedplayer/; s/##MBROLA##/$quotedmbrola/; s/##PT1##/$quotedpath/; print }' pt-speak.in > pt-speak`;
chmod 0755, 'pt-speak';

# Write Makefile........................................

WriteMakefile(
	      NAME => "Lingua::PT::Speaker",
	      EXE_FILES => [qq/pt-speak/],
	      VERSION_FROM => 'lib/Lingua/PT/Speaker.pm',
	      PREREQ_PM => { 'Text::RewriteRules' => 0.25,
			     'Lingua::PT::PLN'    => 0.05 },
	     );
