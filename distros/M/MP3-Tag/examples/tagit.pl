#!/usr/bin/perl -w

use File::Copy;
use MP3::Tag;

# some settings for getting command-line options
use Getopt::Long;
Getopt::Long::Configure(qw/no_ignore_case_always ignore_case bundling/);
my %options = ( '--song=s'    => "Name of the song",
		'--album=s'   => "Album",
		'--artist=s'  => "Artist",
		'--comment=s' => "Comment",
		'--track=i'   => "Track",
		'--genre=s'   => "Genre",
		'--year=i'    => "Year",
		'--removetag' => "Removes an existing tag",
		'-q'          => "Be quiet",
		'-v'          => "Be verbose",
                '-f'          => "Force",
		'--show'      => "Show the existing tag",
		'--showgenres'=> "Show the existing genres (!!not yet!!)",
		'--setfilename' => "Set filename from tag (according to format string)",
		'--getfilename' => "Set tag according to filename (and format string)",
		'--format=s'  => "Set the format string for get/setfilenam (default: %a - %s.mp3)",
		'--nospaces'  => "Replace Spaces through _ in filenames",
		'--test'      => "Do NOT change the files. Only print which changes would be made",
		'--skipwithoutv1' => "Don't do anything if no ID3v1 tag exists",
		'--skipwithv1' => "Don't use --getfilename option if ID3v1 tags already exists",
	       );

# get the command line options
my %opt;
getoptions(\%opt, %options);

if (exists $opt{showgenres}) {
  my $genres = MP3::Tag::genres();
  print join (", ", @$genres) ."\n";
}

unless ($#ARGV >=0) {
  print "error: Filename(s) missing\n" unless exists $opt{showgenres};
  exit 0 if exists $opt{showgenres};
  exit 1;
}

# is there only one or more files to work with?
$opt{single}=1 if $#ARGV==0;

# prepare v and q flag (v has higher priority)
delete $opt{q} if (exists $opt{v} && exists $opt{q});

# prepare for setfilename / getfilename (not allowed together)
if (exists $opt{setfilename} && exists $opt{getfilename}) {
  print "error: Cannot use --setfilename and --getfilename together\n";
  delete $opt{setfilename};
  delete $opt{getfilename};
}
$opt{format} = "%a - %s.mp3" unless exists $opt{format};
my ($stencil, $details);
($stencil, $details) = formatstr_setfilename($opt{format}) if exists $opt{setfilename};
($stencil, $details) = formatstr_getfilename($opt{format}) if exists $opt{getfilename};

# loop for each file
chomp(@ARGV = <STDIN>) unless @ARGV;
for my $filename (@ARGV) {
  # get the tags
  $mp3 = MP3::Tag->new($filename);
  unless (defined $mp3) {
    print "Skipping $filename ...\n";
    next;
  }
  $mp3->get_tags;

  unless (exists $mp3->{ID3v1}) {
    print "No ID3v1-Tag found\n" if exists $opt{show} || exists $opt{v};
    next if exists $opt{skipwithoutv1};
    $mp3->new_tag("ID3v1");
  } else {
    next if exists $opt{skipwithv1};
  }

  # deletet tag if wanted (option: --removetag)
  $mp3->{ID3v1}->remove_tag if $opt{removetag};

  # set tag if this is wanted
  # option: --song, --artist, --album, --comment, --year, --genre, --track
  $mp3->{ID3v1}->song($opt{song}) if exists $opt{song};
  $mp3->{ID3v1}->artist($opt{artist}) if exists $opt{artist};
  $mp3->{ID3v1}->album($opt{album}) if exists $opt{album};
  $mp3->{ID3v1}->comment($opt{comment}) if exists $opt{comment};
  $mp3->{ID3v1}->year($opt{year}) if exists $opt{year};
  $mp3->{ID3v1}->genre($opt{genre}) if exists $opt{genre};
  $mp3->{ID3v1}->track($opt{track}) if exists $opt{track};

  if (exists $opt{song} || exists $opt{artist} || exists $opt{album} || 
      exists $opt{comment} || exists $opt{year} || exists $opt{genre} || exists $opt{track}) {
    if (exists $opt{test}) {
      # do nothing, but show new tag
      $opt{show} = 1;
    } else {
      if ($mp3->{ID3v1}->write_tag()) {
	print "Tag written\n" unless exists $opt{q};
      } else {
	print "Couldn't write tag\n" unless exists $opt{q};
      }
    }
  }

  # show tag (option --show)
  if ($opt{show}) {
    print "\nID3v1-Tag: $filename\n" unless exists $opt{single};
    print "New tag would be:\n" if exists $opt{test};
    print "   Song: " .$mp3->{ID3v1}->song . "\n";
    print " Artist: " .$mp3->{ID3v1}->artist . "\n";
    print "  Album: " .$mp3->{ID3v1}->album . "\n";
    print "Comment: " .$mp3->{ID3v1}->comment . "\n";
    print "   Year: " .$mp3->{ID3v1}->year . "\n";
    print "  Genre: " .$mp3->{ID3v1}->genre . "\n";
    print "  Track: " .$mp3->{ID3v1}->track . "\n";
  }

  # set filename from tag (option: --setfilename)
  # with --format the format of the new filename can be set (see formatstr below)
  if (exists $opt{setfilename}) {
    unless (exists $opt{test}) { # check if there really exists a tag
      $mp3->get_tags;
      unless (exists $mp3->{ID3v1}) {
	print "No ID3v1 Tag exists. Can't change $filename\n";
	exit -1;
      }
    }
    my $new = $stencil;
    my $i=0;
    foreach (@$details) {
      my $txt = $mp3->{ID3v1}->{$_->{tag}};
      $txt =~ s/ *$//;
      $txt = substr $txt, 0, $_->{length} if exists $_->{length} && ((! exists $_->{fill}) || exists  $_->{precise} );
      $txt = $_->{fill} x ($_->{length}-length($txt)) . $txt if exists $_->{fill};
      $new =~ s/%$i/$txt/;
      $i++;
    }
    $new =~ s/ /_/g if exists $opt{nospaces};

    print "Trying to rename $filename to $new\n" if exists $opt{v} && !exists $opt{test};
    print "$filename => $new\n" if exists $opt{test};

    if ( !exists $opt{test} && $new && checkpath($new)) {
      $mp3->close;
      move($filename, $new);
    } else {
      print "Cannot set filename from tag: $new is invalid\n" unless exists $opt{q} || exists $opt{test} ; 
    }
  }

  # set tag from filename (option: --getfilename)
  # with --format the format of the filename can be set
  if (exists $opt{getfilename}) {
	  my @matches;
	  if (@matches = ($filename =~ $stencil)) {
		  while(($key,$val)=each %$details) {
			  $mp3->{ID3v1}->$val($matches[$key]);
		  }
		  if (exists $opt{test} or exists $opt{v} or exists $opt{show}) {
			  print "\nID3v1-Tag: $filename\n" unless exists $opt{single};
			  print "After scanning filename, new tag would be:\n";
			  print "   Song: " .$mp3->{ID3v1}->song . "\n";
			  print " Artist: " .$mp3->{ID3v1}->artist . "\n";
			  print "  Album: " .$mp3->{ID3v1}->album . "\n";
			  print "Comment: " .$mp3->{ID3v1}->comment . "\n";
			  print "   Year: " .$mp3->{ID3v1}->year . "\n";
			  print "  Genre: " .$mp3->{ID3v1}->genre . "\n";
			  print "  Track: " .$mp3->{ID3v1}->track . "\n";
		  }
		  unless (exists $opt{test}) {
			  if ($mp3->{ID3v1}->write_tag()) {
				  print "Tag written\n" unless exists $opt{q};
			  } else {
				  print "Couldn't write tag\n" unless exists $opt{q};
			  }
		  }
	} else {
		print"Couldn't analyze '$filename' with /$stencil/\n" unless exists $opt{q};
	}
  }


}

######################################## SUBS

# check if the path to this file exists
# if not, ask if missing dirs should be created
# return true/false if the path is ok
sub checkpath {
  my $file = shift;
  my $tree=""; my $treeok=1;
  while ($file =~ /([^\/]*)\//g && $treeok) {
    unless ($1 eq "" || -d $tree.$1) {
      print "$tree$1/ doesn't exists!\n" if exists $opt{v};
      $treeok=0;
      last unless confirm("Should I create the directory $tree$1/");
      if (mkdir $tree.$1, 0755) {
	$treeok=1;
      } else {
	print "Cannot create directory $tree$1/\n";
      }
    }
    $tree .=$1."/";
  }
  return $treeok;
}

# prints a question and waits for a [y]es or [n]o
# returns true (1) for [y] or false (o) for [n]
# with option -f (force) returns always true (1)
sub confirm {
  return 1 if $opt{f};

  my $question = shift;
  print $question ." [y/n] ?";

  my $key = <STDIN>;  
  chomp $key;
  return ($key =~ /^[YyJj]/) ? 1 : 0;
}

#######################################

# converts formatstr into the internal dataformat
#
# the formatstr may include any text, valid for a filename
# also it contains symbols,which must start with a % and end with one of [salgyt]
# %s song, %a - artist %l - album, %y -year, %g - genre, %t -track
#
# each symbol can contain additional information:
# a length l, directly after the %
# a fill char, given as :x or !:x where x is the fillchar, and :x or !:x follows after the length
#
# * if there is only a length l given, the string will be max. l chars long, 
#          that means cut off after l chars if it is longer
# * if there is a length and a :x, then a string which is shorter then l chars, 
#          will be filled from left with the char x to meet the length l
#          a longer sting will not be affected
# * if there is a length and a !:x, then a string shorter than l, will also filled
#          from left with x, but a longer string than l, will be cut off at l
#
# eg track=3  artist=Abba  song=Waterloo
# '%2:0t.$a - $s.mp3' will be translated to '03.Abba - Waterloo.mp3'
# '%t.$6!:_a - $6!:_s.mp3' will be translated to '3.__Abba - Waterl.mp3'
#
# intern format contains $stencil and @details
# the stencil contains text and %i makros. i is an integer, counting up from 0
# $details[i] contains {tag} which should be used to replace %i in the stencil
# {length}, {fill} and {precise} give some additional information for replacing
sub formatstr_setfilename {
  my $format = shift;
  my %tags = (s=>"song", a=>"artist", l=>"album", y=>"year", g=>"genre", t=>"track", c=>"comment");
  my @fmt;

  while ($format =~ /%([0-9]*)(?:(!)?:(.))?([salygct])/g) {
    my $t;
    $t->{length}=$1 if defined $1 && $1 ne "";
    $t->{precise}=1 if defined $2 && $2 ne "";
    $t->{fill}=$3 if defined $3 && $3 ne "";
    $t->{tag} = $tags{$4} if defined $4 && $4 ne "";
    push @fmt, $t if defined $4 && $4 ne "";
  }
  my $i=0;
  $format =~ s/%([0-9]*)(?:(!)?:(.))?([salygt])/"%".$i++/eg;
  return ($format, \@fmt);
}

sub formatstr_getfilename {
	my $format = shift;
	my $pos=0;
	my %tags = (s=>"song", a=>"artist", l=>"album", y=>"year", g=>"genre", t=>"track", c=>"comment");
	my %info;
	while ($format =~ /%([salgcyt])/g) {
		$info{$pos++}=$tags{$1};
	}
	$format =~ s/([\[\]*.?()])/\\$1/g;
	$format =~ s/%[yt]/(\\d+)/g;
	$format =~ s/%[salgc]/(.+?)/g;
	return (qr!$format!, \%info);
}

########################################

sub getoptions {
    my ($optref, %options) = @_;
    unless ( GetOptions ($optref, keys %options) ) {
	# found unknown option
	# show usage of options
	print "\nUSAGE: $0 " . join(" ", sort keys %options) ." file(s)\n\n";
	my ($eq, $co, $neg) = (0,0,0); 
	foreach (sort keys %options) {
	    printf "%13s : %s\n", $_, $options{$_};
	    $eq = 1 if /=/;
	    $co = 1 if /:/;
	    $neg = 1 if /!/;
	}
	print "\n" if $eq || $co || $neg;
	print " --switch!  - switch may be negated as --noswitch\n" if $neg;
	print " --switch=x - switch must be followed by a value x\n" if $eq;
	print " --switch:x - switch can be followed by a value x\n" if $co;
	print "             / f - value must be a float\n".
	    "          x =  s - value must be a string\n".
		"             \\ i - value must be an integer\n" if $eq || $co;
	# and exit because of unknown options
	exit(0);
    }
}

