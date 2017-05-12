#!/usr/bin/perl 
#
# TODO
#  implement tags
#  fix init of modes
#
use strict;
use warnings;
use Games::SGF::Go;
use Games::SGF::Util;
use Getopt::Long;
my $input = "";
my $output = "";
my $debug = 0;
my $help = 0;
my $mode = "";
my( %opt ) = ();

$help = 1 unless GetOptions( "input=s"     => \$input,
                             "output=s"    => \$output,
                             "mode=s"      => \$mode,
                             "debug"       => \$debug,
                             "help"        => \$help,
                             "option=s%"   => \&setOption,
                          );
if( $help ) {
   print <<HELP;

sgf_break options:
   --input=STRING      Sets the sgf file the break apart(default: sdtin)
   --output=STRING     Sets the sgf file the break apart(default: stdout)
   --debug             This will turn on Debug messages
   --help              Displays this message
   --mode=STRING       This is the mode which the sgfFilter will use
   --option OPT=VAL    This sets an option, which is mode specific

   MODES

   kgs-comment         Allows filtering of user comments from KGS game records.
   
      OPTIONS

      level
                       This minimium rank a play needs to be for the comment
                       to be sent to output.

      allow:unsettled=1
                       This will allow ? ranked player comments to be sent to
                       the output.

      allow:user:NAME=1
                       Will allow user NAME to be sent to output regardless
                       of settled state or rank.


   comment              a regex comment filter

      OPTIONS

      regex=PATTERN
                        The selection pattern for replacement. If no pattern is
                        set the entire comment will be selected.

      replace=STRING
                        The selected portion of the regex will be replaced with
                        this pattern. If the replacement is not suplied it will
                        be replaced with an empty string.

                        If the resulting STRING is empty the entire comment
                        will be removed.

   tags                 Removes Specified Tags

      OPTIONS

      groups=GROUP,GROUP,...
                        Removes the tag group STRING. The valid groups are:

                        node-ann
                           Node Annotation: C, DM, GB, GW, HO, N, UC, V
                        move-ann
                           Move Annotation: BM, DO, IT, TE
                        markup
                           Markup: AR, CR, DD, LB, LN, MA, SL, SQ, TR
                        timing
                           Timing: BL, OB, OW, WL
      tags=Tag,Tag,...
                        Removes the specified tags. You can not have spaces in
                        the list.
                          
   EXAMPLES

   sgfFilter --mode=comment --option replace="Comment Was Removed"

      This will replace all comments with a notice that they were removed

   sgfFilter --mode=comment

      This completely remove all comments from the FILE

   sgfFilter --mode=kgs-comment --option level=5d --option allow:unsettled=1 \
            --option allow:user:EnragedTux=1

       This will remove all comments of players less then 5 dan and allows those
       to have a unsettled rank. Also passes on all comments by EnragedTux
       untouched.
      
HELP
   exit(0);
}
# now do the work

my $sgf = new Games::SGF::Go(Warn => $debug, Debug => $debug);
my $util = new Games::SGF::Util(SGF => $sgf);
if( $input ) {
   $sgf->readFile($input)
      or die "Failed to read '$input': " . $sgf->Fatal . "\n";
} else {
   my $text = "";
   $text .= $_ while <STDIN>;
   $sgf->readText($text)
      or die "Failed to read SDTIN: " . $sgf->Fatal . "\n";
}

if( $mode eq 'kgs-comment') {
   my($v);
   if($v = $sgf->getProperty("PW") ) {
      $opt{'allow'}->{'user'}->{$v->[0]} = 1;
   }
   if($v = $sgf->getProperty("PB") ) {
      $opt{'allow'}->{'user'}->{$v->[0]} = 1;
   }
   $util->filter("C", \&kgs);
} elsif( $mode eq 'comment') {
   $util->filter("C", \&comment);
} else {
   $opt{'groups'} ||= "";
   $opt{'tags'} ||= "";
   $util->touch(\&tags);
}

if( $output ) {
   $sgf->writeFile($input)
      or die "Failed to read '$output': " . $sgf->Fatal . "\n";
} else {
   my $text = "";
   $text = $sgf->writeText
      or die "Failed to read SDTOUT: " . $sgf->Fatal . "\n";
   print $text;
}

sub isValidRank  {
   my $rank = shift;
   my $minrank = shift;
   if( $rank =~ m/\?/ and not $opt{'allow'}->{'unsettled'} ) {
      return 0;
   }
   my( $lvl, $class) = $rank =~ /^(\d*)([dk])/;
   if( $class eq 'k' ) {
      $lvl = 0 - $lvl;
   }
   my( $min, $cl) = $minrank =~ /^(\d*)([dk])/;
   if( $cl eq 'k' ) {
      $min = 0 - $min;
   }
   if( $lvl >= $min ) {
      return 1;
   } else {
      return 0;
   }
}

sub kgs {
   my $comment = shift;
   my $level = $opt{'level'};
   if( not $level ) {
      comment($comment);
   }

   my $out = "";
   foreach my $line (split /\n/, $comment ) {
      if( $line =~ m/^(\w+)\s+\[(\d+[dk]?\??)\]/ ) {
         my $user = $1;
         my $rank = $2;
         if( $opt{'allow'}->{'user'}->{$user} or
            isValidRank($rank, $opt{'level'} ) ) {
            $out .= $line . "\n";
         }
      } elsif( not($opt{'level'}) and $opt{'allow'}->{'unsettled'} ) {
         $out .= $line . "\n";
      }
   }
   return undef unless $out;
   return $out;
}
sub comment {
   my $comment = shift;
   my $regex = $opt{'regex'} || "";
   my $replace = $opt{'replace'} || "";

   if( $regex ) {
      $comment =~ s/$regex/$replace/g;
      return $comment;
   } elsif( $replace ) {
      return $replace;
   } else {
      return undef;
   }
}

sub setOption {
   my $option = shift;
   my(@keys) = split /:/, shift;
   my $key = pop @keys;
   my $value = shift;
   my $opt = \%opt;
   while(my $k = shift @keys ) {
      $opt->{$k} = {};
      $opt = $opt->{$k};
   }
   # $opt now points to where $value should be stored
   if( not defined $value ) {
      $value = 1;
   }
   $opt->{$key} = $value;
}

sub tags {
   my $sgf = shift;
   # check each tag in set groups
   my(@tags) = split /,/, $opt{'tags'};
   foreach my $group ( split /,/, $opt{'groups'} ) {
      if( $group eq 'node-ann' ) {
         push @tags, "C", "DM", "GB", "GW", "HO", "N", "UC", "V";
      } elsif( $group eq 'move-ann' ) {
         push @tags, "BM", "DO", "IT", "TE";
      } elsif( $group eq 'markup' ) {
         push @tags, "AR", "CR", "DD", "LB", "LN", "MA", "SL", "SQ", "TR";
      } elsif( $group eq 'timing' ) {
         push @tags, "BL", "OB","OW","WL";
      }
   }
   foreach my $tag ( @tags ) {
      my $value = $sgf->setProperty($tag);
   }
   # if present set undef(delete)
   # check each tag in list
   # if set unset
}
