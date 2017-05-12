#!/usr/bin/perl 
use strict;
use warnings;
use Games::SGF::Go;
use Getopt::Long;
my $filename = "";
my $debug = 0;
my $help = 0;
my $exclusive = 0;
my $hits = 0;
my $distance = 5;
my $num = -1;
my $out_dir = "sgf_save";

$help = 1 unless GetOptions( "file=s"     => \$filename,
                             "debug"      => \$debug,
                             "help"       => \$help,
                             "exclusive"       => \$exclusive,
                             "hits=i"       => \$hits,
                             "distance=i" => \$distance,
                             "moves=i"    => \$num,
                             "output=s"   => \$out_dir );
if( $help ) {
   print <<HELP;

sgf_break options:
   --file=STRING      Sets the sgf file the break apart
   --debug            Sets Games::SGF::DEBUG
   --distance=NUMBER  Sets the max distance of a move to count as
                      part of a sequence
   --output=STRING    Sets the directory where the output sequences
                      will be thrown. The files will be of the form
                      /\\d\\d\\d.sgf/
   --moves=NUM        Will only process the first NUM moves
   --exclusive        A move will only be put into one sequence
   --hits=NUM         Will stop processing when a move will falls into NUM
                      sequences.  If NUM equals 0 it will process till the
                      end of the file.(default 0).
HELP
   exit(0);
}
# now do the work

my $results = [];
my $cache = [];
my $sgf = new Games::SGF::Go(Warn => $debug, Debug => $debug);
$sgf->readFile($filename)
   or die "Failed to read '$filename': " . $sgf->Fatal . "\n";
{
   if( $num == 0 ) {
      last;
   }
   $num--;
   my $move;
   if( $move = $sgf->property('B') ) {
      my $cord = $move->[0];
      addNode($sgf->C_BLACK, $cord );
   } elsif( $move = $sgf->property('W') ) {
      my $cord = $move->[0];
      addNode($sgf->C_WHITE, $cord );
   }
   if( $sgf->next ) {
      redo;
   } elsif( $sgf->variations ) {
      $sgf->gotoVariation(0);
      redo;
   }
   # fall out
}
mkdir $out_dir;
for( my $i = 0; $i < @$results; $i++) {
   my $f = sprintf( "$out_dir/sgf-%03u.sgf", $i );
   $results->[$i]->writeFile($f);
}

# returns 0 to stop processing 1 to continue
sub addNode {
   my $color = shift;
   my $cords = shift;
   my $added = 0;
   SGF: for( my $c = 0; $c < @$cache; $c++ ) {
      foreach ( @{$cache->[$c]} ) {
         if( dist( $_, $cords ) < $distance ) {
            print "Adding to SGF\n";
            my $sgf = $results->[$c];
            $sgf->addNode;
            if( $color == $sgf->C_BLACK ) {
               $sgf->property( B => $cords) ;
            } else {
               $sgf->property( W => $cords) ;
            }
            push @{$cache->[$c]}, $cords;
            $added++;
            if( $hits > 0 and $added > $hits ) {
               return 0; 
            }
            if( $exclusive and $added ) {
               last SGF;
            }
            next SGF;
         }
      }
   }
   if( not $added ) {
      print "New SGF\n";
      my $sgf = new Games::SGF::Go(Warn => $debug, Debug => $debug);
      push @$results, $sgf;
      push @{$cache->[@$results -1]}, $cords;
      $sgf->addGame;
      #$sgf->addNode;
      $sgf->property( GM => 1 );
      $sgf->property( FF => 4 );
      $sgf->addNode;
      if( $color == $sgf->C_BLACK ) {
         $sgf->property( B => $cords) ;
      } else {
         $sgf->property( W => $cords) ;
      }
   }
   return 1;
}



sub dist {
   my $c1 = shift;
   my $c2 = shift;

   #return 3;
   return sqrt( ($c1->[0] - $c2->[0])**2  + ($c1->[1] - $c2->[1])**2 );
}
