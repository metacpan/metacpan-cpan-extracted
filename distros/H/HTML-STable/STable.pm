package HTML::STable;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.02';


# Preloaded methods go here.

package SNode;
use strict;

my $obj_id = 0;

sub new {
   my $P = shift;
   my $format = shift;
   my $O = {};
   bless $O,ref $P || $P;
   $O->{ID} = $obj_id++;

   $format  =~ tr/;/,/;
   my @array = split(/,/,$format);
   my %hash  = ();
   my $tag;
   foreach $tag (@array) {
      my ($key, $value) = split(/:/,$tag,2);
      $hash{$key} = $value;
   }
   $O->{hash}  = \%hash;

   if($hash{small}) {
      $O->{small_h} = "<small>";
      $O->{small_t} = "</small>";
   }
   my $align   = $hash{"align"};
   my $valign  = $hash{"valign"};
   my $color   = $hash{"color"};
   my $bgcolor = $hash{"bgcolor"};
   my $background = $hash{"background"};
   my $size    = $hash{"size"};
   my $face    = $hash{face};
   my $bolds   = $hash{"bold"};
   my $colspan = $hash{"colspan"};
   my $rowspan = $hash{"rowspan"};
   my $header  = $hash{"header"};
   my $width   = $hash{"width"};
   $O->{align}   = $align   ? " align=$align"     : "";
   $O->{valign}  = $valign  ? " valign=$valign"   : "";
   $O->{color}   = $color   ? " color=$color"     : "";
   $O->{size}    = $size    ? " size=$size"       : "";
   $O->{face}    = $face    ? " face=$face"       : "";
   $O->{colspan} = $colspan ? " colspan=$colspan" : "";
   $O->{rowspan} = $rowspan ? " rowspan=$rowspan" : "";
   $O->{bgcolor} = $bgcolor ? " bgcolor=$bgcolor" : "";
   $O->{background} = $background ? " background=$background" : "";
   $O->{width}   = $width   ? " width=$width"     : "";
   if($header  eq "yes") { 
       $O->{head} = "<TH";
       $O->{tail} = "</TH>\n";
   } else {
       $O->{head} = "<TD";
       $O->{tail} = "</TD>\n";
   }
   if($bolds   eq "yes") {
      $O->{bold_head} = "<B>";
      $O->{bold_tail} = "</B>";
   } else {
      $O->{bold_head} = "";
      $O->{bold_tail} = "";
   }
   if($color ne "" || $size ne "" || $face ne "") { 
      $O->{color_size_head} = "<font";
      $O->{color_size_tail} = ">";
   } else {
      $O->{color_size_head} = "";
      $O->{color_size_tail} = "";
   }
   $O->{emty_format} = 0;
   if($format eq "") {
      $O->{emty_format} = 1;
   }

   return $O;
}

sub print {
    my $O = shift;
    my $print_string;
    if (@_)  { $print_string = shift; }

    if($O->{emty_format} == 1) {
       if(ref($print_string) eq "CODE") {
          print "<TD>";
          eval($print_string->());
          print "</TD>\n";
       } elsif(ref($print_string)) {
          if(ref($print_string) eq "HTML::STable") {
             if($print_string->{no_table}) {
                $print_string->print();
             } else {
                print "<TD>";
                $print_string->print();
                print "</TD>\n";
             }
          } else {
             print "<TD>";
             $print_string->print();
             print "</TD>\n";
          }
       } else {
          print "<TD>$print_string</TD>\n";
       }
       return;
    }
    my $align   = $O->{align};
    my $valign  = $O->{valign};
    my $color   = $O->{color};
    my $bgcolor = $O->{bgcolor};
    my $background = $O->{background};
    my $size    = $O->{size};
    my $face    = $O->{face};
    my $width   = $O->{width};
    my $bolds   = $O->{bold};
    my $colspan = $O->{colspan};
    my $rowspan = $O->{rowspan};
    my $head    = $O->{head};
    my $tail    = $O->{tail};
    my $bold_h  = $O->{bold_head};
    my $bold_t  = $O->{bold_tail};
    my $col_si_h= $O->{color_size_head};
    my $col_si_t= $O->{color_size_tail};

    if(@_) {
       my $color_size = 0;
       my $format_string  = shift;
          $format_string  =~ tr/;/,/;
       my @array = split(/,/,$format_string);
       my %hash  = ();
       my $tag;
       foreach $tag (@array) {
          my ($key, $value) = split(/:/,$tag,2);
          $hash{$key} = $value;
       }
       my $temp;
       if($temp = $hash{"align"  }) { $align   = " align=$temp"; }
       if($temp = $hash{"valign" }) { $valign  = " valign=$temp"; }
       if($temp = $hash{"width"  }) { $width   = " width=$temp"; }
       if($temp = $hash{"bgcolor"}) { $bgcolor = " bgcolor=$temp"; }
       if($temp = $hash{"background"}) { $background = " background=$temp"; }
       if($temp = $hash{"colspan"}) { $colspan = " colspan=$temp"; }
       if($temp = $hash{"rowspan"}) { $rowspan = " rowspan=$temp"; }
       if($temp = $hash{"size"   }) { $color_size = 1; $size    = " size=$temp"; }
       if($temp = $hash{"face"   }) { $color_size = 1; $face    = " face=$temp"; }
       if($temp = $hash{"color"  }) { $color_size = 1; $color   = " color=$temp"; }
       if($color_size == 1) {
          $col_si_h = "<font";
          $col_si_t = ">";
       }
       if($temp = $hash{"bolds"}) {
          if($temp eq "yes") {
             $bold_h = "<B>";
             $bold_t = "</B>";
          } else {
             $bold_h = "";
             $bold_t = "";
          }
       }
       if($temp = $hash{"header"}) {
          if($temp eq "yes") {
             $head = "<TH";
             $tail = "</TH>\n";
          } else {
             $head = "<TD";
             $tail = "</TD>\n";
          }
       }
    }


    print $head;
    print $align;
    print $valign;
    print $width;
    print $colspan;
    print $rowspan;
    print $bgcolor;
    print $background;
    print ">";
    print $col_si_h;
    print $color;
    print $size;
    print $face;
    print $col_si_t;
    print $bold_h;
    if(ref($print_string) eq "CODE") {
       eval($print_string->());
    } elsif(ref($print_string)) {
       $print_string->print();
    } else {
       print $O->{small_h};
       print $print_string;
       print $O->{small_t};
    }
    print $bold_t;
    print $tail;
}

sub string {
    my $O   = shift;
    my $print_string;
    if (@_)  { $print_string = shift }
    my $str = "";

    $str .= $O->{align};
    $str .= $O->{valign};
    $str .= $O->{width};
    $str .= $O->{colspan};
    $str .= $O->{rowspan};
    $str .= $O->{bgcolor};
    $str .= $O->{background};
    $str .= $O->{color_size_head};
    $str .= $O->{color};
    $str .= $O->{size};
    $str .= $O->{face};
    $str .= $O->{color_size_tail};
    if(ref($print_string)) {
       $str .= $print_string->string();
    } else {
       $str .= $print_string;
    }
    print $O->{bold_tail};
    $str;
}


sub print_list {
    my($O,@lst) = @_;
    my $i;
    for($i = 0; $i <= $#lst; $i++) {
        $O->print($lst[$i]);
    }
}

##############################################
## methods to access per-object data        ##
##                                          ##
## With args, they set the value.  Without  ##
## any, they only retrieve it/them.         ##
##############################################    

sub AUTOLOAD {
   my $O = shift;
   my $attr = $SNode::AUTOLOAD;
   my $argm = shift;

   $attr =~ s/.*:://;
   return if $attr eq 'DESTROY';
   
   { # this block will turn strick refs off
       no strict 'refs';
       *{$SNode::AUTOLOAD} = sub {
          my $O    = shift;
          my $argm = shift;
          if($argm != "") {
             $O->{$attr} = " $attr=$argm";
          } else {
             my ($dummy,$argm) = split(/=/,$O->{$attr});
             return $argm;
          }
      };
   }
   if($argm != "") {
      $O->{$attr} = " $attr=$argm";
   } else {
      my ($dummy,$argm) = split(/=/,$O->{$attr});
      return $argm;
   }
}

sub header {
    my($O,$header) = @_;
    my $f = $O->{hash};
    my $temp = %$f->{"header"};
    %$f->{"header"}  = $header;
    if($header  eq "yes") {
       $O->{head} = "<TH";
       $O->{tail} = "</TH>\n";
    } else {
       $O->{head} = "<TD";
       $O->{tail} = "</TD>\n";
    }
    return $temp;
}

sub blank {
    my($O,$num_of_blank) = @_;
    print "<TD>";
    my $i;
    for($i = 0; $i < $num_of_blank; $i++) {
        print "&#160";
    }
    print "</TD>\n";
}

sub ID {
    my $O = shift;
    $O->{ID};
}

1;  # so the require or use succeeds


package SDate;

use POSIX qw(strftime);
use POSIX;
use Time::Local;

my %hs =
      (JAN=>"01", FEB=>"02", MAR=>"03", APR=>"04",MAY=>"05", JUN=>"06",
       JUL=>"07", AUG=>"08", SEP=>"09", OCT=>"10",NOV=>"11", DEC=>"12");

# Added by Su-Che to map month numeric value to its string representation            
my @mon_map = 
      ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");

use overload (
    '<=>' => \&spaceship,
    '""'  => \&stringify,
    'cmp' => \&compare
);

sub new 
{
   my $P = shift;
   my $O = {};
   bless $O,ref $P || $P;

   my $date = shift;

   my ($m,$d,$y);
   my ($sec,$min,$hour);
   if($date) {
      if ($date =~ "/" )  {               # 12/31/1999
         ($m,$d,$y) = split("/",$date); 
      } elsif ($date =~ "-" ) {           # 31-12-1999
         ($d,$m,$y) = split("-",$date); 
         $m = $hs{uc $m};
         if( $y > 50 ) {
            $y += 1900;
         } else {
            $y += 2000;
         }
      } elsif ($date =~ " " ) {
         $date = uc $date;
         ($m, $d, $y) = split(" ", $date);
         $m = $hs{$m};
      } else {
         my ($a,$b,$c);
         ($a,$b,$c,$d,$m,$y) = localtime($date);
         $y += 1900;
         $m += 1;
      }
   } else {
      ($sec,$min,$hour,$d,$m,$y) = (localtime)[0,1,2,3,4,5];
      $O->{sec}  = $sec;
      $O->{min}  = $min;
      $O->{hour} = $hour;
      $y += 1900;
      $m += 1;
   }

   $O->{month} = $m;
   $O->{day}   = $d;
   $O->{year}  = $y;
   $O->{date} = timelocal(0,0,0,$d,$m-1,$y-1900);

   $O;
}

sub time
{
    my $O = shift;
    return $O->{hour}.":".$O->{min}.":".$O->{sec};
}

sub diff 
{
   my $O = shift;
   my $date = shift;
   if ($date != 0 || $date ne "") {
      return ceil(($O->{date} - $date->seconds) / 86400);
   } else {
      $date = new SDate();
      return ceil(($O->{date} - $date->{date}) / 86400);
   }
}

sub seconds
{
   my $O = shift;
   $O->{date};
}

#+--------------------------------------------------------------+
#| Modified by Su-Che Liao on September 14, 1999                |
#|    To add a new date string format "mon dd yyyy" in addition |
#|    to the default format "mm/dd/yyyy"                        |
#+--------------------------------------------------------------+
sub string 
{
   my $O      = shift;
   my $format = shift;

   my $d = $O->{day};
   if($d < 10) {
      $d = "0".$d;
      $d =~ s/00/0/;
   }

   my $m = $O->{month};
   if ($format eq "mon dd yyyy") {
      return $mon_map[$m-1].' '.$d.' '.$O->{year}; 
   } elsif ($format eq "dd-mon-yyyy") {
      return $d.'-'.$mon_map[$m-1].'-'.$O->{year}; 
   } elsif ($format eq "yyyy/mm/dd") { # default format  
      if($m < 10) {
         $m = "0".$m;
         $m =~ s/00/0/;
      }
      return $O->{year}."/".$m."/".$d;
   } elsif ($format eq "" || $format eq "mm/dd/yyyy") { # default format  
      if($m < 10) {
         $m = "0".$m;
         $m =~ s/00/0/;
      }
      return $m."/".$d."/".$O->{year};
   } elsif ($format eq "yyyymmdd") { # default format  
      if($m < 10) {
         $m = "0".$m;
         $m =~ s/00/0/;
      }
      return $O->{year}.$m.$d;
   }
}

sub add_days
{
   my $O = shift;
   my $days = shift;
   my ($sec, $min,$hou,$d,$m,$y) = localtime($O->{date} + 86400 * $days); 
   $m = $m+1;;
   $y = $y+1900;
   return SDate->new("$m/$d/$y")
} 

sub month_day {
   my $O = shift;
   (localtime $O->{date})[3];
}

sub week_day {
   my $O = shift;
   (localtime $O->{date})[6];
}

sub year_day {
   my $O = shift;
   (localtime $O->{date})[7];
}

sub week_of_year {
   my $O = shift;
   int((localtime $O->{date})[7])/7+1;
}

sub print {
   my $O = shift;
   print "$O->{month}/$O->{day}/$O->{year}";
}

sub spaceship {
    my ($this, $that) = @_;
    my $date;
    if(ref($this) ne "SDate") {
       $date = new SDate($this);
       $this = $date;
    }
    if(ref($that) ne "SDate") {
       $date = new SDate($that);
       $that = $date;
    }
    $this->{date} <=> $that->{date};
}

sub stringify {
     my $O = shift;
     "$O->{month}/$O->{day}/$O->{year}";
}

sub business_days {
    my $O = shift;
    my $date1 = shift;

    my $cycle = $O->diff($date1);
    my $count = 0;
    for( my $i = 0; $i < $cycle; $i++){
      my $date = $date1->add_days($i);
      my $number = $date->week_day;
      if($number == 0) {next;}
      if($number == 6) {next;}
      $count++;
    }
    return $count;
}

sub compare {
    spaceship(@_);
}

1;

use strict;

package HTML::STable; 

sub new {  
    my $P = shift;
    my $format;
    if(@_) {
       $format = shift;
    } else {
       $format = {};
    }
    my $O = {};
    bless $O,ref $P || $P;

    $O->{column_number} = -1;
    $O->{row_number}    = 0;
    $O->{arr}       = undef; # holds the table from sql
    $O->{front}     = ();    # holds strings to put fron
    $O->{back}      = ();    # holds strings to put back 
    $O->{max_row}   = -1;
    $O->{datafile}  = "";
    $O->{form}      = "";
    $O->{sort_flag} = 0;
    $O->{sort_hsh}  = ();
    $O->{sort_key_array} = ();

    $O->{format} = $format;
    $O->{row_number} = -1;
    $O->{column_number} = -1;

    foreach ( keys %$format ) 
    {
         $O->{$_} = $format->{$_};
    }

    #if table_tag => "off" than we do not want to print <TABLE> and </TABLE>
    if($O->{table_tag}) {
        $O->{no_table} = 1;
    }

    if($format->{delimiter} eq "") {
       $O->{delimiter}      = ", ";
    }

    $O->{flag} = undef;  # holds flag for each node, if flag set than format has changed
                         # for a particular node
    $O->{max_row} = -1;
#   following information will be used in renew method of Matrix.pm
    $O->{print_columns_keep} = $O->{print_columns};

    my $i;
    $O->{column_nodes}  = ();
    $O->{node_nodes}    = ();

    if($format->{filename}) {
       open(FH,">>$format->{filename}") || warn "could not open $format->{filename}";
       *STDOUT  = *FH;
       $O->{fh} = *FH;
    } else {
       $O->{fh} = *STDOUT;
    }
    $O->{cur_row} = 0;

    $O->{cur_col} = 0;
    return $O;
}

sub print {
    my $O = shift;
    my $i;
    my $row_num = $O->{row_number};
    $O->print_head;
    if($O->{sort_flag}) {
       my @keys = @{$O->{sort_key_array}};
       my %hsh  = %{$O->{sort_hsh}}; 
       my $key;
       my $rn = 0;
       foreach $key (@keys) {
          # we add one therefore we must remove it    #@#@
          $O->print_row($hsh{$key} - 1);              #@#@
          $rn++;
       }
       # this rows added after sort therefore they will be displayed
       # at the bottom without a sort
       for(my $i = $rn; $i <= $row_num; $i++) {
           $O->print_row($i);
       }
    } else {
       #write the rest of the table
       for ($i = 0; $i <= $row_num; $i++) {
           $O->print_row($i);
       }
    } 
    $O->print_tail;
}

sub nextrow {
    my $O = shift;
    $O->{cur_row}++;
    $O->{cur_col} = 0;
}

sub insert {
    my $O = shift;
    my ($arg1,$arg2,$arg3,$arg4) = @_;
    my ($row,$col,$txt,$fmt);

    # insert([ values ], "optional_format")
    # insert([ values ], [optional_format])
    if(ref($arg1) eq "ARRAY") {
       $col = 0;
       $row = $O->{row_number} + 1;
       $O->{cur_row} = $row;
       $fmt = $arg2;
       if(ref($fmt) eq "ARRAY") {
          foreach (@{$arg1}) {
             $O->insert($row,$col,$arg1->[$col],$fmt->[$col]);
             $col++;
          }
       } else {
          foreach (@{$arg1}) {
             $O->insert($row,$col,$_,$fmt);
             $col++;
          }
       }
       return;
    }
    # insert(row, [ values ], "optional_format")
    if(ref($arg2) eq "ARRAY") {
       $col = 0;
       $row = $arg1;
       $fmt = $arg3;
       if(ref($fmt) eq "ARRAY") {
          foreach (@{$arg2}) {
             $O->insert($row,$col,$arg2->[$col],$fmt->[$col]);
             $col++;
          }
       } else {
          foreach (@{$arg2}) {
             $O->insert($row,$col,$arg2->[$col],$fmt);
             $col++;
          }
       }
       return;
    }

    # insert(row, col, [ values ], "optional_format") 
    if(ref($arg3) eq "ARRAY") {
       $row  = $arg1;
       $col  = $arg2;
       $fmt  = $arg4;
       my $i = 0;
       if(ref($fmt) eq "ARRAY") {
          foreach (@{$arg3}) {
             $O->insert($row,$col,$arg3->[$i],$fmt->[$i]);
             $i++;
             $col++;
          }
       } else {
          foreach (@{$arg3}) {
             $O->insert($row,$col,$arg3->[$i++],$fmt);
             $col++;
          }
       }
       return;
    }
    # insert(value, "optional_format") 
# delete this only keep whatever inside else
    if($#_ <= 1) {
       $txt = $arg1;
       $fmt = $arg2;
       if($txt eq "\n") {
          $O->nextrow;
          return;
       }
       $col = $O->{cur_col};
       if($O->{cur_row} == $O->{row_number}) {
          $row = $O->{row_number} + 1;
       } else {
          $row = $O->{row_number};
       }
       $O->{cur_col}++;
    } else {
       ($row,$col,$txt,$fmt) = ($arg1,$arg2,$arg3,$arg4);
    }

    if($row < 0 || $col < 0) {
       my ($package, $filename, $line) = caller(0);
       print ERROR ref($O).": Error at $filename at line $line  \n";
       print ERROR ref($O).": Negative index ROW = $row COL = $col \n";
       exit;
    }

    if($O->{row_number} < $row) {
       $O->{row_number} = $row;
    }
    if($O->{column_number} < $col) {
       $O->{column_number} = $col;
    }

    if($O->{alter_row_formats}) {
       my $count = $#{$O->{alter_row_formats}} + 1;
       my $index = $row % $count;
       $count = $#{$O->{headers}};
       if($count < 0) { $count = $col; }
       for(my $j = $col; $j <= $count; $j++)
       {
          if($O->{chessboard}) {
             $index = ($row + $j) % 2;
          }
          $fmt = $O->{alter_row_formats}[$index];
          $O->{node_nodes}[$row][$j] = new SNode($fmt);
          $O->{flag}[$row][$j] = 200;
       }
       $O->{arr}[$row][$col] = $txt;
       return;
    }
    $O->{flag}[$row][$col] = 100;   # value inserted but no format changes
    if($fmt ne "") { #if there is a format string

# add new format values into front of body_format. First accurance has 
# precedence, if ve redefine color old color will be overridden.
#      $fmt = $fmt.";".$O->{body_format};
# node format has higher precedence that column_formats and
# column formats has higher precedence than body_format

       $fmt = $O->{body_format}.";".$O->{column_formats}[$col].";".$fmt;
       $O->{node_nodes}[$row][$col] = new SNode($fmt);
       $O->{flag}[$row][$col] = 200;   # value inserted and there is format changes
    }
    $O->{arr}[$row][$col] = $txt;
}

sub column_insert {
    my $O = shift;
    my ($arg1,$arg2,$arg3,$arg4) = @_;
    my ($row,$col,$ar,$fmt);

    if(ref($arg2) eq "ARRAY") 
    {
       $row = 0;
       $col = $arg1;
       $ar  = $arg2;
       $fmt = $arg3; 
    } else {
       $row = $arg1;
       $col = $arg2;
       $ar  = $arg3;
       $fmt = $arg4; 
    }
    foreach (@{$ar}) {
       $O->insert($row,$col,$ar->[$row],$fmt); 
       $row++;
    }
}

sub delimiter {
    my $O = shift;
    return $O->{delimiter};
}

sub cell_format
{
    my $O   = shift;
    my $row = shift;
    my $col = shift;
    my ($ar)  = @_;

    if(ref($ar)) {
       my $fmt;
       foreach $fmt (@{$ar}) {
          $O->{node_nodes}[$row][$col] = new SNode($fmt);
          # value inserted and there is format changes
          $O->{flag}[$row][$col] = 200;
          $col++;
       }
    } else {
       my $fmt = $ar;
       $O->{node_nodes}[$row][$col] = new SNode($fmt);
       # value inserted and there is format changes
       $O->{flag}[$row][$col] = 200;
    }
}

sub row_format 
{
    my $O = shift;
    my $row = shift;
    my $fmt = shift;
    my $cn  = $O->{column_number};
    my $i;
    for($i = 0; $i <= $cn; $i++) {
        $O->cell_format($row,$i,$fmt);
    }
}

sub print_head {
    my $O = shift;
    my ($i,$j);
    $O->{head_nodes} = new SNode($O->{head_format});
    my $temp_node;
    my $col_num = $#{$O->{print_columns}};
    my $row_num = $O->{row_number};

    if($col_num <= $O->{column_number}) {
       $col_num = $O->{column_number};
       if($#{$O->{print_columns}} < 0) {
          $O->{print_columns} = [0..$col_num];
       } else {
          $col_num = $#{$O->{print_columns}};
       }
    }

    if($O->{title}) {
       $O->title($O->{title});
    }
    if($O->{date} eq "yes") {
       $O->date;
    } else {
       $O->title($O->{date});
    }
    if($O->{sub_title}) {
       $O->_sub_title;
    }

    if($row_num < 0) {
       if(ref($O->{empty_msg}) eq "HTML::STable") {
          $O->{empty_msg}->print;
       } else {
          print "<center><font color=red size =5>
                 <BR>$O->{empty_msg}<BR></font></center>";
       }
       return;
    }

    for($i = 0; $i <= $col_num; $i++) {
        my $k = $O->{print_columns}[$i];
        if($O->{column_formats}[$k] eq "" ) {
           $O->{column_nodes}[$k] = new SNode($O->{body_format});
        } else {
           my $fmt = $O->{body_format}.";".$O->{column_formats}[$k];
           $O->{column_nodes}[$k] = new SNode($fmt);
        }
    }

    if($O->{no_table} != 1) {
       my $fmt = $O->{table_format};
       $fmt =~ tr/;/ /;
       $fmt =~ tr/:/=/;
       if(!($fmt =~ /align/)) {
          $fmt .= " align=center"; # default alignment for table
       }
       print "\n<TABLE $fmt>\n";
    }

#first write headers
    if($O->{headers}) { # if present than headers will be printed
       print "<TR>\n";
       $temp_node = $O->{head_nodes};
       for($j = 0; $j <= $col_num; $j++) {
           my $k = $O->{print_columns}[$j];
           $temp_node->print($O->{headers}[$k]);
       }
       print "</TR>\n";
    }
}

sub print_row {
    my $O = shift;
    my $i = shift;
    my $j;
    my $temp_node;
    my $col_num = $#{$O->{print_columns}};
    print "<TR>\n";
    for($j = 0; $j <= $col_num; $j++) {
       my $k = $O->{print_columns}[$j];
       $temp_node = $O->{column_nodes}[$k];
       if($O->{flag}[$i][$k] == 100 || $O->{flag}[$i][$k] == 200) {
           if($O->{flag}[$i][$k] == 200) {
              $temp_node = $O->{node_nodes}[$i][$k];
           }
# check whether colspan or rowspan has been used or not,
# if they are used set $O->{flag}[?][?] = 400
# by doing that table printing will skip extra cells
           my $col_span = $temp_node->colspan;
           if($col_span != 0) {
              my $c;
              for($c = 1; $c < $col_span; $c++) {
                  $O->{flag}[$i][$k+$c] = 400;
              }
           }
           my $row_span = $temp_node->rowspan;
           if($row_span != 0) {
              my $r;
              for($r = 1; $r < $row_span; $r++) {
                 $O->{flag}[$i+$r][$k] = 400;
              }
           }
           if($row_span != 0 && $col_span != 0) {
              my ($c,$r);
              for($c = 1; $c < $col_span; $c++) {
              for($r = 1; $r < $row_span; $r++) {
                 $O->{flag}[$i+$r][$k+$c] = 400;
              }
              }
           }
           my $tobj = $O->{arr}[$i][$k];
           if(ref($tobj)) {
              $temp_node->print($tobj);
           } else {
              if($tobj =~ "<HR>") {
                 $temp_node->print($O->{front}[$i][$j].
                                   $tobj.
                                   $O->{back}[$i][$k]." ");
              } else {
                 if($tobj eq "" && $O->{empty_cell_text}) {
                    $O->_null_empty("empty",$k,$temp_node);
                 } else {
                    $temp_node->print($O->{front}[$i][$j].
                                   $tobj.
                                   $O->{back}[$i][$k]."&#160 ");
                 }
              }
           }
       } else {
           if($O->{flag}[$i][$k] != 400) {
              if($O->{null_cell_text}) {
                 $O->_null_empty("null",$k,$temp_node);
              } else {  
                 $temp_node->print("&#160 ");
              }
           }
       }
    }
    print "</TR>\n";
}

sub print_tail {
    my $O = shift;
    if($O->{no_table} != 1) {
       print "</TABLE>\n";
    }

    my $str = $O->{download};
    # if $str ne "" then download the data
    if($str) {
       $O->download;
       $O->show_button($str);
    }
}

sub table_format   {
    my $O = shift;
    my $fmt = shift;
    $fmt =~ tr/;/ /;
    $fmt =~ tr/:/=/;
    $O->{table_format}   = $fmt;
}

sub head_format    { my $O = shift; $O->{head_format}    = shift;}
sub body_format    { my $O = shift; $O->{body_format}    = shift;}
sub column_formats { my $O = shift; $O->{column_formats} = shift;}
sub print_columns  { my $O = shift; $O->{print_columns}  = shift;}
sub headers        { my $O = shift; $O->{headers}        = shift;}
sub empty_msg      { my $O = shift; $O->{empty_msg}      = shift;}
sub sub_title      { my $O = shift; $O->{sub_title}      = shift;}
sub alter_row_formats { my $O = shift; $O->{alter_row_formats} = shift;}

sub my_insert {my $O = shift; sub { $O->insert(@_)};}
sub my_linkto {my $O = shift; sub { $O->linkto(@_)};}
sub my_script {my $O = shift; sub { $O->script(@_)};}

sub sort {
    require Sort::Fields;
    my $O = shift;
    my $cols = shift;

    my %hsh; 

    my ($i,$j);

    my $row_num = $O->{row_number};
    my $col_num = $O->{column_number};

    my %d_indx = ();
    my %a_indx = ();
    # convert d to n for numeric date sort
    foreach ( @$cols ) {
       # increment all column numbers by one
       s/([0-9]+)/$1+1/e;
       if(/d/) {
          my $ind = $_;
          $ind =~ tr/[\-d]/ /;
          $ind =~ s/ //g;
          tr/d/n/;
          $d_indx{$ind} = 1;
       }
       # remove "i" from column name
       if(/i/) {
          my $ind = $_;
          $ind =~ tr/[\-i]/ /;
          $ind =~ s/ //g;
          s/i//;
          $a_indx{$ind} = 1;
       }
       if(/A/) { # convert A tag to 0 to obey all rules of Sort::Fields
          tr/A/0/;
       }
    }
    for($i = 0; $i <= $row_num; $i++) {
        my $tmp = "";
        my @arr = ();
        for($j = 0; $j <= $col_num; $j++) {
           if($d_indx{$j+1}) {
              push(@arr, SDate->new($O->node($i,$j))->seconds);
           } elsif($a_indx{$j+1}) {
              push(@arr, uc ($O->node($i,$j)));
           } else {
              my $val;
              if(ref($O->node($i,$j))) {
                 $val = ref($O->node($i,$j));
              } else {
                 $val = $O->node($i,$j);
              }
              $val =~ s/\://g; 
              push(@arr, $val);
           }
        }
        $tmp = join("\:",@arr);
        while(exists($hsh{$tmp})) {
           $tmp .= "a";
        }
        # we add 1 here to make  while loop work with $i = 0   #@#@
        $hsh{$tmp} = $i + 1;                                   #@#@
    }

    my @keys;

    @keys = Sort::Fields::fieldsort('\:', $cols,  (keys %hsh));

    $O->{sort_hsh} = \%hsh; 
    $O->{sort_key_array} =  \@keys;
    $O->{sort_flag} = 1;
}

sub sum
{
    my $O   = shift;
    my $col = shift;
    my $row = $O->{row_number};

    my $sum = 0;
    for(my $i = 0; $i <= $row; $i++) {
        $_ = $O->node($i,$col);
        tr/[$a-zA-Z]//;
        s/,//g;
        $sum += $_;
    }
    if(@_) {
       if($_[0]->{comma})
       {
          $_ = $sum;
          1 while s/^(-?\d+)(\d{3})/$1,$2/;
          if($_[0]->{dolar}) {
             return '$'.$_;
          }
          return $_;
       }
    }

    return $sum;
}

sub table_tag_off {
    my $O = shift;
    $O->{no_table} = 1;
    return $O;
}

sub null_cell_text {
    my $O = shift;
    $O->{null_cell_text} = shift;
}

sub null_cell_format {
    my $O = shift;
    $O->{null_cell_format} = shift;
}

sub empty_cell_text {
    my $O = shift;
    $O->{empty_cell_text} = shift;
}

sub empty_cell_format {
    my $O = shift;
    $O->{empty_cell_format} = shift;
}
sub _null_empty {
    my $O = shift;
    my $typ = shift;
    my $k   = shift;
    my $temp_node = shift;
    my $txt = $typ."_cell_text";
    my $fmt = $typ."_cell_format";
    if(ref($O->{$txt})) {
       my @val = @{$O->{$txt}};
       if(ref($O->{$fmt})) {
          my @fmt = @{$O->{$fmt}};
          my $node = SNode->new($fmt[$k]);
          $node->print($val[$k]);
       } else {
          if($O->{$fmt}) {
             my $node = SNode->new($O->{$fmt});
             $node->print($val[$k]);
          } else {
             $temp_node->print($val[$k]);
          }
       }
    } else {
       if($O->{$fmt}) {
          if(ref($O->{$fmt})) {
             my @fmt = @{$O->{$fmt}};
             my $node = SNode->new($fmt[$k]);
             $node->print($O->{$txt});
          } else {
             my $node = SNode->new($O->{$fmt});
             $node->print($O->{$txt});
          }
       } else {
          $temp_node->print($O->{$txt});
       }
    }
}

sub rown {
    my $O = shift;
    return $O->{row_number};
}

sub coln {
    my $O = shift;
    return $O->{column_number};
}

sub renew {
    my $O = shift;
    $O->{column_number} = -1;
    $O->{row_number}    = -1;
    $O->{arr}     = ();  
    $O->{front}   = ();
    $O->{back}    = ();
    $O->{max_row} = -1;
    $O->{datafile} = "";
    $O->{form} = "";
    $O->{print_columns} = $O->{print_columns_keep};

    return $O;
}

# use display method instead of print;
sub display { my $O = shift; $O->print(); };


# node function without argument returns the scalar value contained in the node
# however if node function is called with an argument, it will set node valeue
# to the argument, BUT will return whatever value existed in the node before
# set operation

sub node {
    my ($O,$row,$col) = @_;
    unless($col =~ /\D/) {   
       return $O->{arr}[$row][$col];
    } else {
       return $O->{arr}[$row]{$col};
    }
}

sub cell {
    my ($O,$row,$col,$val) = @_;
    if($val) {
       $O->{arr}[$row][$col] = $val;
    } else {
       unless($col =~ /\D/) {   
          return $O->{arr}[$row][$col];
       } else {
          return $O->{arr}[$row]{$col};
       }
    }
}

sub row {
    my ($O,$row) = @_;
    if(ref($O->{arr}[$row]) eq "ARRAY") {
       return @{$O->{arr}[$row]};
    } else {
       return %{$O->{arr}[$row]};
    }
}

sub column {
    my ($O,$col) = @_;
    my $rn = $O->{row_number};
    my $i;
    my @arr = ();
    for($i = 0; $i < $rn; $i++) {
        $arr[$i] = $O->node($i,$col);
    }
    if($O->node($rn,$col) ne "") {
       $arr[$rn] = $O->node($i,$col);
    }

    return @arr;
}

sub hash {
    my ($O,$col1, $col2) = @_;
    my $rn = $O->{row_number};
    my $i;
    my %hsh = ();
    for($i = 0; $i < $rn; $i++) {
        $hsh{$O->node($i,$col1)} = $O->node($i,$col2);
    }
    if($O->node($rn,$col2) ne "") {
        $hsh{$O->node($rn,$col1)} = $O->node($rn,$col2);
    }
    return %hsh;
}

# this sub reads content of a file and load's matrix with this data
sub read {
    my $O  = shift;
    my $ch   = shift;  # character used as field delimiter
    my $file = shift;  # file to be read

    open (FILER, "$file") or warn "Could't open $file\n";

    my $i = 0;
    while(<FILER>) {
        chop;
        my @larr = split(/$ch/);

        my $len = $#larr;
        if($len > $O->{column_number}) {
           $O->{column_number} = $len;
        }
        $O->{arr}[$i] = [ split(/$ch/) ];
        $i++;
    }
    $O->{row_number}    = $i;
   
    close(FILER);
}

sub maxRow {
    my ($O) = shift;
    $O->{max_row} = shift;
}

sub form {
    my $O = shift;
    @_ ? $O->{form} = shift : $O->{form};
}

sub title {
    my $O   = shift;
    my $title = shift;
    if(ref($title)) { 
       my $tit;
       foreach $tit (@{$title}) {
          print "<center> <H2> $tit </H2></center><BR>\n";
       }
    } else {
       if($title) {
          print "<center> <H2> $title </H2></center>\n";
       }
    }
}

sub _sub_title {
    my $O   = shift;
    my $len = $#{$O->{sub_title}};
    my $j;
    my $node;
    for($j = 0; $j <= $len; $j++) {
        if(ref($O->{sub_title_format})) {
           $node = new SNode($O->{sub_title_format}->[$j]);
        } else {
           $node = new SNode($O->{sub_title_format});
        }
        print '<center>';
        $node->print($O->{sub_title}->[$j]);
        print '</center><BR>';
    }
}

sub date {
    my $O  = shift;
    my $flag = shift;
    my $date;
    my $date_phrase;
    $_ = POSIX::ctime(time);
#   meaning of $[d] is given below
#   Mon Sep 21 10:49:15 1998
#   $1  $2  $3 $4       $5
    if (/(\w*)\s*(\w*)\s*(\d*)\s*(..:..:..)\s*(....)/) {
        $date_phrase = "Report generated $1 $2 $3, $5 at $4";
        $date = "$1 $2 $3, $5 at $4";
    }

    if($flag == 1) {
       return $date;
    } else {
       $O->{phrase} = $date_phrase;
       print "<center> <H3> $date_phrase </H3></center>\n";
    }
}

sub clear {
    my ($O,$row,$col) = @_;
    $O->{front}[$row][$col] = "";
    $O->{back}[$row][$col]  = "";
}

sub change {
    my ($O,$row,$col,$tx1,$tx2) = @_;
    $O->{front}[$row][$col] = $tx1.$O->{front}[$row][$col];
    $O->{back}[$row][$col]  = $O->{back}[$row][$col].$tx2;
}

sub script {
    my $O    = shift;
    my $arg1 = shift;
    my $arg2 = shift;

    if($arg2 =~ /[a-zA-Z]/) {
#      if user call this function as $ip->javascript(0,"SelectSite",7,8)'
#      this routine will produce something like
#      <A HREF=javascript:SelectSite(site_id,cust_id)> Site_Name </A>
#      at the first line 7 and 8 are column number containing site_id
#      and cust_id respectively
       my $col = $arg1;
       my $prg = $arg2;
       my $cols = shift;
  
       my ($i,$j);
       my $rn = $O->{row_number};
       my $tx2 = "<A HREF=javascript:".$prg."(";
       if($O->{form} ne "") {
          $tx2 .= $O->{form};
          if($#$cols > 0) {
             $tx2 .= ",";
          }
       }

       for($i = 0; $i <= $rn;    $i++) {
           my $tx3 = "";
           for($j = 0; $j <= $#$cols; $j++) {
               $_ = $O->{arr}[$i][$cols->[$j]];
               if(/^[-+]?[0-9]+(\.[0-9]*)?$/) {
                  $tx3 .= $_;
               } else {
                  if(/this\./) {
                     $tx3 .= $_;
                  } else {
                     $tx3 .= "\"".$_."\"";
                  }
               }
               if($j < $#$cols) {
                  $tx3 .= ",";
               }
           }
           $O->{front}[$i][$col] = $tx2.$tx3.")> ";
           $O->{back}[$i][$col]  = " </A>";
       }
    } else {
       my $row = $arg1;
       my $col = $arg2;
       my $prg = shift;
       my $arg = shift;
       my $tx2 = "<A HREF=javascript:".$prg."(";
       foreach ( @{$arg}) {
#         if(/[a-zA-Z_]/) {
#            $_ = '"'.$_.'"';
#         }
          if(/[a-zA-Z_]/) {
             if(/this\./) {
                $_ = $_;
             } else {
                $_ = '"'.$_.'"';
             }
          }
       }
       my $tx3 = join(',',@{$arg});
       $O->{front}[$row][$col] = $tx2.$tx3.")> ";
       if($O->{arr}[$row][$col] =~ "</A>") {
          $O->{back}[$row][$col]  = " ";
       } else {
          $O->{back}[$row][$col]  = "</A>";
       }
    }
}


sub back {
    my $O = shift;
    my $row = shift;
    my $col = shift;
    if(@_) {
       my $tmp = $O->{back}[$row][$col];
       $O->{back}[$row][$col] = shift;
       return $tmp;
    } else {
       return $O->{back}[$row][$col];
    }
}

sub front {
    my $O = shift;
    my $row = shift;
    my $col = shift;

    if(@_) {
       my $tmp = $O->{front}[$row][$col];
       $O->{front}[$row][$col] = shift;
       return $tmp;
    } else {
       return $O->{front}[$row][$col];
    }
}

sub linkto {
    my $O = shift;
    my $row = shift;
    my $col = shift;
    # set back value to anchor closing, user can overrite it
    # by colling back function
    $O->{back}[$row][$col] = " </A>";
    $_  = shift;
    $O->{front}[$row][$col] = "<A HREF = $_>";
}

sub download {
    my $O = shift;

    my $col_num = $#{$O->{print_columns}};
    my $row_num = $O->{row_number};
### This lines moved from print_head method to run
### download function before print function
    if($col_num <= $O->{column_number}) {
       $col_num = $O->{column_number};
       if($#{$O->{print_columns}} < 0) {
          $O->{print_columns} = [0..$col_num];
       } else {
          $col_num = $#{$O->{print_columns}};
       }
    }
#####
    my $datafile = "data.".$$;
    $O->{datafile} = $datafile;

#   open (FILE, '>>/tmp/'.$datafile);
    open (FILE, '>C:/apache/tmp/'.$datafile);

    if(ref($O->{title})) {
       my $tit;
       foreach $tit (@{$O->{title}}) {
          print FILE "$tit\r\n";
       }
    } else {
       print FILE "$O->{title}\r\n";
    }
    print FILE "$O->{phrase}\r\n";
    my $len = $#{$O->{sub_title}};
    my $j;
    for($j = 0; $j <= $len; $j++) {
        $_ = $O->{sub_title}[$j];
        s/<BR>/ /g;
        print FILE $_,"\r\n";
    }
    print FILE "<table border=3>\r\n";
    #for header
    print FILE "<tr>"; 
    my $rn = $O->{row_number};
    if($rn >= 0) {
       my $len = $#{$O->{headers}};
       for($j = 0; $j <= $len; $j++)
       {
           print FILE "<td>";
           print FILE $O->{headers}[$j];
       }
    } else {
       print FILE $O->{empty_msg};
    }
    print FILE "</tr>\n";

    #for table
    my $i;
    $len = $#{$O->{print_columns}};
    if($O->{sort_flag}) {
       my $tmp1 = $O->{sort_key_array};
       my @keys = @$tmp1;
       my $key;
       foreach $key (@keys) {
          print FILE "<tr>";
          my $tmp2 = $O->{sort_hsh};
          my %tmp  = %$tmp2;
          # we added one in Table.pm to this value    #@#@
          $i = $tmp{$key} - 1;                        #@#@
          for $j (0 .. $len) {
               print FILE "<td>";
               my $tO = $O->{arr}[$i][$O->{print_columns}[$j]];
               if(ref($tO) eq "HTML::STable") {
                  my @tarr  = $tO->column(0);
                  $_ = @tarr;
               } elsif(ref($tO)) {
                  $_ = $tO->download;
               } else {
                  $_ = $tO;
               }
               if ($_) {
                  s/<BR>/ /g;
               } else {
                  $_ = "&nbsp"; 
               }
               print FILE $_;
           }
           print FILE "</tr>\n";
       }
    } else {
       for($i = 0; $i <= $rn; $i++) {
          print FILE "<tr>";
          for $j ( 0 .. $len) {
               print FILE "<td>";
               my $tO = $O->{arr}[$i][$O->{print_columns}[$j]];
               if(ref($tO) eq "HTML::STable") { 
                  $_ = $tO->column(0);
               } elsif(ref($tO)) {
                  $_ = $tO->download;
               } else {
                  $_ = $tO;
               }
               if ($_) {
                  s/<BR>/ /g;
               } else {
                  $_ = "&nbsp";
               }
               print FILE $_;
          }
          print FILE "</tr>\n";
       }
    }
    print FILE "</table>";
    close (FILE);
}

sub show_button
{
    my $O   = shift;
    my $str = shift;
    my $datafile  = $O->{datafile};

    if($str) {

       print "<center><BR>";
       print qq{<INPUT TYPE="button"
                       NAME="download"
                       VALUE="$str"
                       ONCLICK="location.href='download.pl?process_id=$$';">};
       print "</center>";
    }
}

1;
# Autoload methods go after =cut, and are processed by the autosplit program.

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

HTML::STable - Perl extension for HTML Tables. 

=head1 SYNOPSIS

   use HTML::STable; 
   use strict;

   my $table = HTML::STable->new;
   $table->insert(0,0,"Larry");
   $table->insert(0,1,"Wall");
   $table->insert(1,0,"Randal");
   $table->insert(1,1,"Schwartz");
   $table->insert(2,["Tom","Christiansen"]);
   $table->insert(3,0,["Tim","Bunce"]);
   display $table;

=head1 DESCRIPTION

Stub documentation for HTML::STable was created by h2xs.
HTML::STable (Simple Table) has many futures to make HTML Table
creation and use simple. Since it has so many futures, I wanted
to show all the futures of this module by using simple programs.
This programs also help me to find bugs. After a change in the
module I run these programs for possible bugs. You can find these
programs at

http://users.rcn.com/seyhan

If you have any question, or you want to have simple program to show
how the particular future of HTML::STable is used, send me an e-mail
at

seyhan@rcn.com

so that I can add a test program for you.
=head1 AUTHOR

Seyhan Ersoy, seyhan@rcn.com
Documentation of HTML::Stable is located at.
http://users.rcn.com/seyhan

=head1 COPYRIGHT

You may use and distribute HTML::STable module
under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 ACKNOWLEDGEMENTS

I would like to acknowledge the valuable contributions of the many
people I have worked with on the HTML::STable project, especially to Olcay
Boz. I also thank my wife Zeynep Ersoy for her patience and support.

=head1 SUPPORT / WARRANTY

The HTML::STable is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 SEE ALSO

perl(1).

=cut
