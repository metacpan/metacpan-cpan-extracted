package List::Parseable;
# Copyright (c) 2008-2010 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################
# TODO
########################################################################

# (type TYPE ELE0 ELE1 ...)    extracts elements of the given TYPE
# (istype TYPE ELE0 ELE1 ...)  true of all elements are of the given TYPE

########################################################################

require 5.000;
use warnings;
use Text::Balanced qw(extract_bracketed extract_tagged);
use Sort::DataTypes 3.00 qw(sort_valid_method sort_by_method);
use Storable qw(dclone);

use strict;
our($VERSION);
$VERSION = "1.06";

########################################################################
# METHODS
########################################################################

sub new {
   my($class,%opts) = @_;

   my $self = { "err"    => "ignore",
                "warn"   => "quiet"
              };
   bless $self,$class;

   return $self;
}

sub version {
   return $List::Parseable::VERSION;
}

# $self = { err  => exit|return|ignore
#           warn => stdout|stderr|both|quiet
#         }
#
sub errors {
   my($self,@opts) = @_;
   foreach my $opt (@opts) {
      if ($opt eq "exit"    ||
          $opt eq "return"  ||
          $opt eq "ignore") {
         $$self{"err"} = $opt;

      } elsif ($opt eq "stderr"  ||
               $opt eq "stdout"  ||
               $opt eq "both"    ||
               $opt eq "quiet") {
         $$self{"warn"} = $opt;

      } else {
         die "ERROR: invalid error option: $opt\n";
      }
   }
}

sub list {
   my($self,$name,@list) = @_;
   $$self{"list"}{$name} = [ @list ];
}

sub string {
   my($self,$name,$string) = @_;
   my @list = _string($string);
   $$self{"list"}{$name} = [ @list ];
}

sub eval {
   my($self,$name) = @_;
   return _eval($self,@{ $$self{"list"}{$name} });
}

sub vars {
   my($self,%hash) = @_;
   foreach my $var (keys %hash) {
      $$self{"vars"}{$var} = $hash{$var};
   }
}

########################################################################
# LIST PARSING
########################################################################

sub _eval {
   my($self,@list) = @_;

   # Step 1 - parse all children

   my @tmp;
   foreach my $ele (@list) {
      if (ref($ele) eq "ARRAY") {
         push(@tmp,_eval($self,@$ele));
      } elsif (ref($ele)) {
         die "ERROR: invalid list element";
      } else {
         push(@tmp,$ele);
      }
   }
   @list = @tmp;

   # Step 2 - separate the list into operations and arguments

   my(@ops,@args);
   while (@list) {
      my $ele = shift(@list);

      if (_operation($self,1,$ele)) {
         push(@ops,$ele);

      } elsif ($ele eq "--") {
         @args = @list;
         last;

      } else {
         @args = ($ele,@list);
         last;
      }
   }

   # Step 3 - perform operations

   while (@ops) {
      my $op = pop(@ops);
      @args = _operation($self,0,$op,@args);
   }
   return @args;
}

########################################################################
# STRING PARSING
########################################################################

# This parses a string which must contain a single list (though other
# lists may be nested inside it).
#
sub _string {
   my($string) = @_;
   my(@list);

   while ($string) {
      next  if ($string =~ s/^\s+//);

      # Test to make sure that the string consists only of a single list
      # and nothing else.
      #
      # string     = "(: (- a-b):foo:bar )"
      #
      # match      = "(- a-b):foo:bar"
      # remainder  = ""
      # eledelim   = ":"

      my($match,$remainder,$eledelim,$nestedchar) = __string_list($string,1);
      if ($match eq "") {
         die "ERROR: invalid list string (no list delimiter):\n   $string";
      }
      if ($remainder ne "") {
         die "ERROR: invalid list string (remainder):\n   $string";
      }
      $string = "";

      # Each element in the list is either a nested list or a scalar element.

      while ($match ne "") {
         my($m,$r,$d,$n) = ("","","","");
         ($m,$r,$d,$n)   = __string_list($match,0)  if (! $nestedchar);

         if ($m ne "") {

            # match = "(- a-b ):foo:bar"
            #
            # m     = "(- a-b )"
            # r     = ":foo:bar"
            # d     = "-"

            if ($r  &&  $eledelim  &&  $r !~ s/^\Q$eledelim\E//) {
               die "ERROR: invalid element contains list and scalar:\n   $string\n";
            }
            push(@list,[ _string($m) ]);
            $match = $r;

            # r     = "foo:bar"
            # @list = (... [ a, b ])
            # match = "foo:bar"

         } else {

            # match = "foo:bar"

            if ($eledelim) {
               if ($match =~ s/^(.*?)\Q$eledelim\E//) {
                  my $val = $1;
                  $val = ""  if (! defined $val);
                  push(@list,$val);
                  push(@list,"")  if ($match eq "");
               } else {
                  push(@list,$match);
                  $match = "";
               }

            } else {
               $match =~ s/(\S+)\s*//;
               push(@list,$1);
            }
         }
      }
   }

   return @list;
}

# Finds a list at the start of the string. Extracts it, removes the
# list delimiter (and optional element delimiter), and removes the
# list delimiters from the start and end of the extracted string. It
# returns:
#
#   a string containing the list
#   the rest (if any) of the string
#   the element delimiter
#   any special character (\) following the list delimiter
#
sub __string_list {
   my($string,$strip) = @_;
   my($delim,$nested,$eledelim);

   if ($string =~ /^\s*([\050\133\173])(\134)?([[:punct:]]\S*)?/) {

      my($delim,$nested,$eledelim)  = ($1,$2,$3);
      $nested   = ""  if (! $nested);
      $eledelim = ""  if (! $eledelim);
      $string   =~ s/^\s+//;
      my($match,$remainder) = extract_bracketed($string,$delim);
      if (! defined $match) {
         die "ERROR: invalid list string (incomplete list):\n   $string";
      }
      $remainder =~ s/^\s+//;

      if ($strip) {
         $match =~ s/^\Q$delim$nested$eledelim\E\s*//;
         $match =~ s/\s*.$//;
      }

      return($match,$remainder,$eledelim,$nested);

   } else {
      return ("");
   }
}

########################################################################
# OPERATIONS
########################################################################

sub _operation {
   my($self,$test,$op,@args) = @_;

   #
   # Meta operations
   #

   if      ($op eq "scalar") {
      return 1  if ($test);
      return @args;

   } elsif ($op eq "list") {
      return 1  if ($test);
      return [ @args ];
   }

   #
   # List => scalar operations
   #

   if      ($op eq "count") {
      return 1  if ($test);
      return $#args+1;

   } elsif ($op eq "countval") {
      return 1  if ($test);
      my $i = 0;
      my $val = shift(@args);
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            $i++  if ($val eq $ele);
         }
      }
      return $i;

   } elsif ($op eq "minval") {
      return 1  if ($test);
      my $min = $args[0];
      foreach my $val (@args) {
         if (ref($val)) {
            return undef  if (_error($self,$op,$val));
         } else {
            $min = $val  if ($val < $min);
         }
      }
      return $min;

   } elsif ($op eq "maxval") {
      return 1  if ($test);
      my $max = $args[0];
      foreach my $val (@args) {
         if (ref($val)) {
            return undef  if (_error($self,$op,$val));
         } else {
            $max = $val  if ($val > $max);
         }
      }
      return $max;

   } elsif ($op eq "nth") {
      return 1  if ($test);
      my $n = shift(@args);
      if (ref($n)  ||
          $n !~ /^[-+]?\d+$/  ||
         ! _valid_index($n,$#args)) {
         _error($self,$op,$n);
         return undef;
      } else {
         return $args[$n];
      }

   } elsif ($op eq "case") {
      return 1  if ($test);

      while ($#args > 0) {
         my $test = shift(@args);
         my $val  = shift(@args);
         if (ref($test)) {
            _error($self,$op,$test);
            return undef;
         }
         return $val  if ($test);
      }
      if (@args) {
         return $args[0];
      }
      return ();

   } elsif ($op eq "indexval") {
      return 1  if ($test);
      my $val  = shift(@args);
      if (ref($val)) {
         _error($self,$op,$val);
         return undef;
      }
      for (my $i=0; $i<=$#args; $i++) {
         return $i  if (! ref($args[$i])  &&  $args[$i] eq $val);
      }
      return -1;

   } elsif ($op eq "rindexval") {
      return 1  if ($test);
      my $val  = shift(@args);
      if (ref($val)) {
         _error($self,$op,$val);
         return undef;
      }
      for (my $i=$#args; $i>=0; $i--) {
         return $i  if (! ref($args[$i])  &&  $args[$i] eq $val);
      }
      return -1;

   } elsif ($op eq "join") {
      return 1  if ($test);
      my $delim;
      if ($args[0] eq "delim") {
         shift(@args);
         $delim = shift(@args);
         if ($delim eq "_space_") {
            $delim = " ";
         } elsif ($delim eq "_null_") {
            $delim = "";
         } elsif ($delim eq "_tab_") {
            $delim = "\t";
         } elsif ($delim eq "_nl_") {
            $delim = "\n";
         }
      } else {
         $delim = " ";
      }

      my @list;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            push(@list,$ele);
         }
      }
      return join($delim,@list);

   } elsif ($op eq "+"  ||  $op eq "*") {
      return 1  if ($test);
      my $ret = ($op eq "+" ? 0 : 1);
      foreach my $ele (@args) {
         if (ref($ele)  ||
             ! _isnum($ele)) {
            return undef  if (_error($self,$op,$ele));
         } elsif ($op eq "+") {
            $ret += $ele;
         } else {
            $ret *= $ele;
         }
      }
      return $ret;

   } elsif ($op eq "-"  ||  $op eq "/") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])  ||
          ! _isnum($args[0])  ||
          ! _isnum($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      if ($op eq "-") {
         return $args[0] - $args[1];
      } else {
         if ($args[1] == 0) {
            _error($self,$op,$args[1]);
            return undef;
         }
         return $args[0] / $args[1];
      }
   }

   #
   # List => boolean operations
   #

   if      ($op eq "mintrue") {
      return 1  if ($test);
      my $n = shift(@args);
      my $i = 0;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            $i++  if ($ele);
         }
      }
      return 1  if ($i >= $n);
      return 0;

   } elsif ($op eq "maxtrue") {
      return 1  if ($test);
      my $n = shift(@args);
      my $i = 0;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            $i++  if ($ele);
         }
      }
      return 1  if ($i <= $n);
      return 0;

   } elsif ($op eq "numtrue") {
      return 1  if ($test);
      my $n = shift(@args);
      my $i = 0;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            $i++  if ($ele);
         }
      }
      return 1  if ($i == $n);
      return 0;

   } elsif ($op eq "minfalse") {
      return 1  if ($test);
      my $n = shift(@args);
      my $i = 0;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            $i++  if (! $ele);
         }
      }
      return 1  if ($i >= $n);
      return 0;

   } elsif ($op eq "maxfalse") {
      return 1  if ($test);
      my $n = shift(@args);
      my $i = 0;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            $i++  if (! $ele);
         }
      }
      return 1  if ($i <= $n);
      return 0;

   } elsif ($op eq "numfalse") {
      return 1  if ($test);
      my $n = shift(@args);
      my $i = 0;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            $i++  if (! $ele);
         }
      }
      return 1  if ($i == $n);
      return 0;

   } elsif ($op eq "and") {
      return 1  if ($test);
      return _operation($self,0,"maxfalse",0,@args);

   } elsif ($op eq "or") {
      return 1  if ($test);
      return _operation($self,0,"mintrue",1,@args);

   } elsif ($op eq "not") {
      return 1  if ($test);
      return _operation($self,0,"maxtrue",0,@args);

   } elsif ($op eq "member") {
      return 1  if ($test);
      my $val = shift(@args);
      if (ref($val)) {
         _error($self,$op,$val);
         return undef;
      }
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            return 1  if ($val eq $ele);
         }
      }
      return 0;

   } elsif ($op eq "absent") {
      return 1  if ($test);
      my $val = shift(@args);
      if (ref($val)) {
         _error($self,$op,$val);
         return undef;
      }
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            return 0  if ($val eq $ele);
         }
      }
      return 1;

   } elsif ($op eq ">") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])  ||
          ! _isnum($args[0])  ||
          ! _isnum($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] > $args[1]);
      return 0;

   } elsif ($op eq ">=") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])  ||
          ! _isnum($args[0])  ||
          ! _isnum($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] >= $args[1]);
      return 0;

   } elsif ($op eq "==") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])  ||
          ! _isnum($args[0])  ||
          ! _isnum($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] == $args[1]);
      return 0;

   } elsif ($op eq "<=") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])  ||
          ! _isnum($args[0])  ||
          ! _isnum($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] <= $args[1]);
      return 0;

   } elsif ($op eq "<") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])  ||
          ! _isnum($args[0])  ||
          ! _isnum($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] < $args[1]);
      return 0;

   } elsif ($op eq "!=") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])  ||
          ! _isnum($args[0])  ||
          ! _isnum($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] != $args[1]);
      return 0;

   } elsif ($op eq "gt") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] gt $args[1]);
      return 0;

   } elsif ($op eq "ge") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] ge $args[1]);
      return 0;

   } elsif ($op eq "eq") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] eq $args[1]);
      return 0;

   } elsif ($op eq "le") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] le $args[1]);
      return 0;

   } elsif ($op eq "lt") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] lt $args[1]);
      return 0;

   } elsif ($op eq "ne") {
      return 1  if ($test);
      if ($#args != 1  ||
          ref($args[0])  ||
          ref($args[1])) {
         _error($self,$op,\@args);
         return undef;
      }
      return 1  if ($args[0] ne $args[1]);
      return 0;

   } elsif ($op eq "if") {
      return 1  if ($test);
      if ($#args < 0  ||
          $#args > 2) {
         _error($self,$op,\@args);
         return undef;
      }
      my $test = shift(@args);
      if (ref($test)) {
         _error($self,$op,$test);
         return undef;
      }
      if ($test) {
         if (@args) {
            return shift(@args);
         } else {
            return 1;
         }
      } else {
         if ($#args == 1) {
            return pop(@args);
         } else {
            return 0;
         }
      }

   } elsif ($op eq "is_equal") {
      return 1  if ($test);
      if ($#args != 1  ||
          ! ref($args[0])  ||
          ! ref($args[1])) {
         _error($self,$op,$test);
         return undef;
      }

      my %list1;
      foreach my $ele (@{ $args[0] }) {
         if (ref($ele)) {
            _error($self,$op,$ele);
            return undef;
         }
         $list1{$ele}++;
      }

      my %list2;
      foreach my $ele (@{ $args[1] }) {
         if (ref($ele)) {
            _error($self,$op,$ele);
            return undef;
         }
         $list2{$ele}++;
      }

      foreach my $ele (keys %list1) {
         return 0  if (! exists $list2{$ele}  ||  $list1{$ele} != $list2{$ele});
      }
      foreach my $ele (keys %list2) {
         return 0  if (! exists $list1{$ele}  ||  $list1{$ele} != $list2{$ele});
      }
      return 1;

   } elsif ($op eq "not_equal") {
      return 1  if ($test);
      my $val = _operation($self,0,"is_equal",@args);
      if (defined $val) {
         return ($val ? 0 : 1);
      } else {
         return undef;
      }

   } elsif ($op eq "iff") {
      return 1  if ($test);
      my $t = 0;
      my $u = 0;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
            $u++;
         } else {
            $t++  if ($ele);
         }
      }
      return 1  if ($t+$u == 0  ||  $t+$u == $#args + 1);
      return 0;

   } elsif ($op eq "range"   ||
            $op eq "rangeL"  ||
            $op eq "rangeR"  ||
            $op eq "rangeLR") {
      return 1  if ($test);
      if ($#args != 2    ||
          ref($args[0])  ||
          ref($args[1])  ||
          ref($args[2])  ||
          ! _isnum($args[0])  ||
          ! _isnum($args[1])  ||
          ! _isnum($args[2])  ||
          $args[1] > $args[2]) {
         _error($self,$op,[@args]);
      }
      my($n,$x,$y) = @args;
      return 0  if ($n < $x  ||
                    ($n == $x  &&  ($op eq "rangeL"  ||  $op eq "rangeLR"))  ||
                    $n > $y  ||
                    ($n == $y  &&  ($op eq "rangeR"  ||  $op eq "rangeLR")));
      return 1;

   }

   #
   # List => list operations
   #

   if      ($op eq "flatten") {
      return 1  if ($test);
      return _flatten(@args);

   } elsif ($op eq "union") {
      return 1  if ($test);
      my @ret;
      foreach my $ele (@args) {
         if (ref($ele)) {
            push(@ret,@$ele);
         } else {
            push(@ret,$ele);
         }
      }
      return @ret;

   } elsif ($op eq "sort") {
      return 1  if ($test);
      my @list;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            push(@list,$ele);
         }
      }

      sort_by_method("alphabetic",\@list);
      return @list;

   } elsif ($op eq "sort_by_method") {
      return 1  if ($test);
      if (ref($args[0])  ||
          ! sort_valid_method($args[0])) {
         _error($self,$op,$args[0]);
         return undef;

      } elsif (! ref($args[1])) {
         _error($self,$op,$args[1]);
         return undef;

      } else {
         sort_by_method(@args);
      }
      return @{ $args[1] };

   } elsif ($op eq "unique") {
      return 1  if ($test);
      my %ele = ();
      my @ret = ();
      foreach my $ele (_flatten(@args)) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            if (! exists $ele{$ele}) {
               push(@ret,$ele);
               $ele{$ele} = 1;
            }
         }
      }
      return @ret;

   } elsif ($op eq "compact") {
      return 1  if ($test);
      my @ret = ();
      foreach my $ele (_flatten(@args)) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            next  if (! defined $ele  ||  $ele eq "");
            push(@ret,$ele);
         }
      }
      return @ret;

   } elsif ($op eq "true") {
      return 1  if ($test);
      my @ret = ();
      foreach my $ele (_flatten(@args)) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            push(@ret,$ele)  if ($ele);
         }
      }
      return @ret;

   } elsif ($op eq "pop") {
      return 1  if ($test);
      pop(@args);
      return @args;

   } elsif ($op eq "shift") {
      return 1  if ($test);
      shift(@args);
      return @args;

   } elsif ($op eq "pad") {
      return 1  if ($test);
      if (ref $args[0]  ||
          $args[0] !~ /^[-+]?\d+$/) {
         return undef  if (_error($self,$op,$args[0]));

      } else {
         my $len = shift(@args);
         my @ret;
         foreach my $ele (@args) {
            if (ref($ele)) {
               return undef  if (_error($self,$op,$ele));
            } else {
               my $val = $ele;
               if ($len >= 0) {
                  $val .= " "x($len-length($val));
               } else {
                  $val = " "x(-$len-length($val)) . $val;
               }
               push(@ret,$val);
            }
         }
         return @ret;
      }

   } elsif ($op eq "padchar") {
      return 1  if ($test);
      if (ref($args[0])  ||
          $args[0] !~ /^[-+]?\d+$/) {
         return undef  if (_error($self,$op,$args[0]));

      } elsif (ref($args[1])  ||
               length($args[1]) != 1) {
         return undef  if (_error($self,$op,$args[1]));

      } else {
         my $len = shift(@args);
         my $c   = shift(@args);
         my @ret;
         foreach my $ele (@args) {
            if (ref($ele)) {
               return undef  if (_error($self,$op,$ele));
            } else {
               my $val = $ele;
               if ($len >= 0) {
                  $val .= $c x ($len-length($val));
               } else {
                  $val = $c x (-$len-length($val)) . $val;
               }
               push(@ret,$val);
            }
         }
         return @ret;
      }

   } elsif ($op eq "column") {
      return 1  if ($test);
      my $n = shift(@args);
      if (ref($n)  ||
          $n !~ /^[-+]?\d+$/) {
         _error($self,$op,$n);
         return undef;
      }

      my @ret;
      foreach my $ele (@args) {
         if (! ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            push(@ret,$$ele[$n])  if (defined $$ele[$n]);
         }
      }
      return @ret;

   } elsif ($op eq "reverse") {
      return 1  if ($test);
      return reverse(@args);

   } elsif ($op eq "rotate") {
      return 1  if ($test);
      my $n   = shift(@args);
      if (ref($n)  ||  $n !~ /^[-+]?\d+$/) {
         _error($self,$op,$n);
         return undef;
      }
      my $dir = 1;
      if ($n < 0) {
         $dir = 0;
         $n  *= -1;
      }
      if ($dir) {
         for (my $i=0; $i<$n; $i++) {
            push(@args,shift(@args));
         }
      } else {
         for (my $i=0; $i<$n; $i++) {
            unshift(@args,pop(@args));
         }
      }
      return @args;

   } elsif ($op eq "delete") {
      return 1  if ($test);
      my $val = shift(@args);
      if (ref($val)) {
         _error($self,$op,$val);
         return undef;
      }

      my @ret;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            push(@ret,$ele)  unless ($ele eq $val);
         }
      }
      return @ret;

   } elsif ($op eq "clear") {
      return 1  if ($test);
      return ();

   } elsif ($op eq "append") {
      return 1  if ($test);
      my $str = shift(@args);
      if (ref($str)) {
         _error($self,$op,$str);
         return undef;
      }

      my @ret;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            push(@ret,"$ele$str");
         }
      }
      return @ret;

   } elsif ($op eq "prepend") {
      return 1  if ($test);
      my $str = shift(@args);
      if (ref($str)) {
         _error($self,$op,$str);
         return undef;
      }

      my @ret;
      foreach my $ele (@args) {
         if (ref($ele)) {
            return undef  if (_error($self,$op,$ele));
         } else {
            push(@ret,"$str$ele");
         }
      }
      return @ret;

   } elsif ($op eq "splice") {
      return 1  if ($test);
      my $list = shift(@args);
      if (! ref($list)) {
         _error($self,$op,$list);
         return undef;
      }
      my @list = @$list;
      my $n = shift(@args);
      if (ref($n)  ||
          $n !~ /^[-+]?\d+$/  ||
          ! _valid_index($n,$#list)) {
         _error($self,$op,$n);
         return undef;
      }
      my $len = shift(@args);
      if (ref($len)  ||  $len !~ /^\d+$/) {
         _error($self,$op,$len);
         return undef;
      }
      splice(@list,$n,$len,@args);
      return @list;

   } elsif ($op eq "slice") {
      return 1  if ($test);
      my $n = shift(@args);
      if (ref($n)  ||
          $n !~ /^[-+]?\d+$/  ||
          ! _valid_index($n,$#args - 1)) {
         _error($self,$op,$n);
         return undef;
      }
      my $len = shift(@args);
      if (ref($len)  ||  $len !~ /^\d+$/) {
         _error($self,$op,$len);
         return undef;
      }
      return splice(@args,$n,$len);

   } elsif ($op eq "fill") {
      return 1  if ($test);
      if ($#args < 0  ||
          $#args > 3) {
         _error($self,$op,\@args);
         return undef;
      }
      my $list = shift(@args);
      if (! ref($list)) {
         _error($self,$op,$list);
         return undef;
      }
      my @list = @$list;

      my $n;
      if (@args) {
         $n = shift(@args);
      } else {
         $n = 0;
      }
      if (ref($n)  ||  $n !~ /^[-+]?\d+$/) {
         _error($self,$op,$n);
         return undef;
      }

      my $len;
      if (@args) {
         $len = shift(@args);
         if (ref($len)  ||  $len !~ /^[-+]?\d+$/) {
            _error($self,$op,$len);
            return undef;
         }
         return @list  if (! $len);
      }

      my $val = "";
      if (@args) {
         $val = shift(@args);
      }

      # Translate (N,LEN) to (X,Y) where X is index of
      # the first element to set and Y is the index of
      # the last element to set, and negative indexes
      # now refer to elements to add on the left.

      my($x,$y);

      if (! defined $len) {
         if ($n < 0) {
            $x = $n + $#list + 1;
         } else {
            $x = $n;
         }
         if ($x < 0) {
            $y = $x;
         } elsif ($x > $#list) {
            $y = $x;
         } else {
            $y = $#list;
         }

      } elsif ($len < 0) {
         if ($n < 0) {
            $y = $n + $#list + 1;
         } else {
            $y = $n;
         }
         $x = $y + $len + 1;
         $len *= -1;

      } else {
         if ($n < 0) {
            $x = $n + $#list + 1;
         } else {
            $x = $n;
         }
         $y = $x + $len - 1;
      }

      # If $x refers to elements left of the list, add them
      # and adjust ($x,$y) accordingly.

      while ($x < 0) {
         unshift(@list,"");
         $x++;
         $y++;
      }

      while ($y > $#list) {
         push(@list,"");
      }

      # Now set the list range to the value.

      if (ref($val)) {
         for (my $i=$x; $i<=$y; $i++) {
            $list[$i] = dclone($val);
         }

      } else {
         for (my $i=$x; $i<=$y; $i++) {
            $list[$i] = $val;
         }
      }

      return @list;

   } elsif ($op eq "difference" || $op eq "d_difference") {
      return 1  if ($test);
      if (! ref($args[0])  ||
          ! ref($args[1])) {
         _error($self,$op,[@args]);
         return undef;
      }
      my @list1 = @{ $args[0] };
      my @list2 = @{ $args[1] };

      my %list2;
      foreach my $ele (@list2) {
         $list2{$ele}++;
      }

      my @ret;
      foreach my $ele (@list1) {
         if ($op eq "difference") {
            push(@ret,$ele)  if (! exists $list2{$ele});
         } else {
            if (exists $list2{$ele}  &&  $list2{$ele} > 0) {
               $list2{$ele}--;
            } else {
               push(@ret,$ele);
            }
         }
      }
      return @ret;

   } elsif ($op eq "intersection" || $op eq "d_intersection") {
      return 1  if ($test);
      if (! ref($args[0])  ||
          ! ref($args[1])) {
         _error($self,$op,[@args]);
         return undef;
      }
      my @list1 = @{ $args[0] };
      my @list2 = @{ $args[1] };

      my %list2;
      foreach my $ele (@list2) {
         $list2{$ele}++;
      }

      my @ret;
      foreach my $ele (@list1) {
         if (exists $list2{$ele}  &&  $list2{$ele} > 0) {
            $list2{$ele}--;
            push(@ret,$ele);
         }
      }
      @ret = _operation($self,0,"unique",@ret)  if ($op eq "intersection");
      return @ret;

   } elsif ($op eq "symdiff" || $op eq "d_symdiff") {
      return 1  if ($test);
      if (! ref($args[0])  ||
          ! ref($args[1])) {
         _error($self,$op,[@args]);
         return undef;
      }
      my @list1 = @{ $args[0] };
      my @list2 = @{ $args[1] };

      my %list1;
      foreach my $ele (@list1) {
         $list1{$ele}++;
      }
      my %list2;
      foreach my $ele (@list2) {
         $list2{$ele}++;
      }

      my @ret;
      if ($op eq "symdiff") {
         foreach my $ele (@list1) {
            push(@ret,$ele)  unless (exists $list2{$ele});
         }
         foreach my $ele (@list2) {
            push(@ret,$ele)  unless (exists $list1{$ele});
         }
         @ret = _operation($self,0,"unique",@ret);

      } else {
         foreach my $ele (keys %list1) {
            if (exists $list2{$ele}) {
               my $min = _operation($self,0,"minval",$list1{$ele},$list2{$ele});
               $list1{$ele} -= $min;
               $list2{$ele} -= $min;
            }
         }
         foreach my $ele (@list2) {
            if (exists $list1{$ele}) {
               my $min = _operation($self,0,"minval",$list1{$ele},$list2{$ele});
               $list1{$ele} -= $min;
               $list2{$ele} -= $min;
            }
         }
         foreach my $ele (@list1) {
            push(@ret,$ele), $list1{$ele}--  if ($list1{$ele}>0);
         }
         foreach my $ele (@list2) {
            push(@ret,$ele), $list2{$ele}--  if ($list2{$ele}>0);
         }
      }

      return @ret;

   }

   #
   # Variable operations
   #

   if      ($op eq "getvar") {
      return 1  if ($test);
      return undef  if ($#args != 0  ||
                        ref($args[0])  ||
                        ! exists $$self{"vars"}{$args[0]});
      if (ref($$self{"vars"}{$args[0]})) {
         return @{ $$self{"vars"}{$args[0]} };
      } else {
         return $$self{"vars"}{$args[0]};
      }

   } elsif ($op eq "setvar") {
      return 1  if ($test);
      return undef  if ($#args != 1  ||
                        ref($args[0]));
      $$self{"vars"}{$args[0]} = $args[1];
      return $$self{"vars"}{$args[0]};

   } elsif ($op eq "default") {
      return 1  if ($test);
      return undef  if ($#args != 1  ||
                        ref($args[0]));
      $$self{"vars"}{$args[0]} = $args[1]
        unless (exists $$self{"vars"}{$args[0]});
      return $$self{"vars"}{$args[0]};

   } elsif ($op eq "unsetvar") {
      return 1  if ($test);
      return undef  if ($#args != 0  ||
                        ref($args[0]));
      delete $$self{"vars"}{$args[0]}  if (exists $$self{"vars"}{$args[0]});
      return undef;

   } elsif ($op eq "pushvar"  ||  $op eq "unshiftvar") {
      return 1  if ($test);
      return undef  if ($#args != 1  ||
                        ref($args[0]));
      my $var = $args[0];
      if ($op eq "pushvar") {
         if (exists $$self{"vars"}{$var}) {
            if (ref($$self{"vars"}{$var})) {
               push @{ $$self{"vars"}{$var} },$args[1];
            } else {
               $$self{"vars"}{$var} = [ $$self{"vars"}{$var}, $args[1] ];
            }
         } else {
            $$self{"vars"}{$var} = [ $args[1] ];
         }
      } else {
         if (exists $$self{"vars"}{$var}) {
            if (ref($$self{"vars"}{$var})) {
               unshift @{ $$self{"vars"}{$var} },$args[1];
            } else {
               $$self{"vars"}{$var} = [ $args[1], $$self{"vars"}{$var} ];
            }
         } else {
            $$self{"vars"}{$var} = [ $args[1] ];
         }
      }
      return undef;

   } elsif ($op eq "popvar"  ||  $op eq "shiftvar") {
      return 1  if ($test);

      return undef  if ($#args != 0  ||
                        ref($args[0])  ||
                        ! exists $$self{"vars"}{$args[0]}  ||
                        ! ref($$self{"vars"}{$args[0]}));
      if ($op eq "popvar") {
         return pop @{ $$self{"vars"}{$args[0]} };
      } else {
         return shift @{ $$self{"vars"}{$args[0]} };
      }

   }

   #
   # Error
   #

   return 0  if ($test);
   die "ERROR: impossible error: _operation: $op";
}

########################################################################
# MISC
########################################################################

sub _flatten {
   my(@list) = @_;

   my @ret = ();
   foreach my $ele (@list) {
      if (ref($ele) eq "ARRAY") {
         push(@ret,_flatten(@$ele));
      } else {
         push(@ret,$ele);
      }
   }

   return @ret;
}

# This tests a list index ($n) to see if it is valid for a list
# containing $length+1 elements (i.e. $#list was passwd in as
# the second element).
#
# List index can go from 0 to $length or -($length+1) to -1.
#
sub _valid_index {
   my($n,$length) = @_;
   return 1  if ($n >= 0  &&  $n <= $length);
   return 1  if ($n >= -($length+1)  &&  $n <= -1);
   return 0;
}

sub _ele_to_string {
   my($ele) = @_;

   if (ref($ele)) {
      my @string = ();
      foreach my $e (@$ele) {
         push(@string,_ele_to_string($e));
      }
      return '[ ' . join(" ",@string) . ' ]';

   } else {
      return $ele;
   }
}

sub _error {
   my($self,$op,$ele) = @_;
   my $string = _ele_to_string($ele);

   if      ($$self{"warn"} eq "stderr" || $$self{"warn"} eq "both") {
      warn "WARNING: invalid argument: $op: $string\n";
   }

   if      ($$self{"warn"} eq "stdout" || $$self{"warn"} eq "both") {
      print "WARNING: invalid argument: $op: $string\n";
   }

   exit      if ($$self{"err"} eq "exit");
   return 1  if ($$self{"err"} eq "return");
   return 0;
}

########################################################################
# FROM MY PERSONAL LIBRARIES
########################################################################

sub _isnum {
  my($n,$low,$high)=@_;
  return undef    if (! defined $n);
  return 0        if ($n !~ /^\s*([+-]?)\s*(\d+\.?\d*)\s*$/  and
                      $n !~ /^\s*([+-]?)\s*(\.\d+)\s*$/);
  $n="$1$2";
  if (defined $low  and  length($low)>0) {
    return undef  if (! _isnum($low));
    return 0      if ($n<$low);
  }
  if (defined $high  and  length($high)>0) {
    return undef  if (! _isnum($high));
    return 0  if ($n>$high);
  }
  return 1;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:
