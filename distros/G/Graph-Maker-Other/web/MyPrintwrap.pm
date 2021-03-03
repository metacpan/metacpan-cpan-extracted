# Copyright 2014, 2015, 2016, 2017, 2019, 2020 Kevin Ryde
#
# MyPrintwrap.pm is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyPrintwrap.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyPrintwrap;
use 5.006;
use strict;
use warnings;
use Carp;
use base 'Exporter';

our @EXPORT_OK = ('printwrap','printwrap_newline',
                  'printwrap_indent','printwrap_add_indent',
                  'printwrap_suffix',
                  '$Printwrap',
                  'printwrap_gp_matrix','printwrap_gp_vector',
                  'printwrap_poly',
                 );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


use vars '$Printwrap';
$Printwrap = 0;

# printwrap($str,$str,...) print each given string.  If a string would go
# past 80 columns then print a newline before it.  Any newlines within each
# $str are recognised as resetting the column position.
#
# printwrap_indent($str) set the indentation to print after a newline for
# printwrap().
#
# printwrap_newline() print a newline, if not already at the start of a
# line.

my $column = 0;
my $indent = '';
my $suffix = '';

sub printwrap_indent {
  my ($str) = @_;
  $indent = $str;
}
sub printwrap_add_indent {
  my ($str) = @_;
  $indent .= $str;
}
sub printwrap_suffix {
  my ($str) = @_;
  $suffix = $str;
}

sub _split_by_newlines {
  my ($str) = @_;
  my @ret;
  my $pos = 0;
  for (;;) {
    my $nl = index($str,"\n",$pos);
    if ($nl < 0) {
      # no more newlines
      if ($pos < length($str)) {
        push @ret, substr($str,$pos);
      }
      return @ret;
    }
    if ($nl > $pos) {
      # non-empty string
      push @ret, substr($str,$pos, $nl-$pos);
    }
    push @ret, "\n";
    $pos = $nl+1;
  }
}

sub printwrap {
  foreach my $str (map {_split_by_newlines($_)} @_) {
    if ($str eq "\n") {
      print $suffix,$str;
      $column = 0;
      next;
    }
    if ($column && $column+length($str)+length($suffix) > 79) {
      print $suffix,"\n";
      $column = 0;
    }
    if ($column == 0) {
      print $indent, (' ' x $Printwrap);
      $column = length($indent) + $Printwrap;
      $str =~ s/^[ \t]*//;
    }
    print $str;
    $column += length($str);
  }
}
sub printwrap_newline {
  if ($column > 0) {
    printwrap("\n");
  }
}

sub printwrap_gp_matrix {
  my ($aref, $name, %options) = @_;
  my $space = $options{'space'} // ' ';
  my $close;
  if (defined $name) {
    printwrap("$name = {[");
    $close = "]};\n";
  } else {
    printwrap("[");
    $close = "]";
  }
  local $Printwrap = $Printwrap + 2;
  foreach my $i (0 .. $#$aref) {
    my $row = $aref->[$i];
    printwrap(($i!=0 ? $space : '')
              . join(',',@$row)
              . ($i < $#$aref ? ';' : $close));
  }
}
sub printwrap_gp_vector {
  my ($aref, $name) = @_;
  printwrap("$name = {[");
  local $Printwrap = $Printwrap + 2;
  foreach my $i (0 .. $#$aref) {
    my $value = $aref->[$i];
    if (! defined $value) { $value = "'none"; }
    printwrap($value . ($i < $#$aref ? ',' : "]};\n"));
  }
}

# $points is an arrayref [ [$x1,$y1], [$x2,$y2], ... ] which is points of a
# polygon.  Print them as ($x1,$y1)--($x2,$y2)--...--cycle
sub printwrap_poly {
  my ($points) = @_;
  return unless @$points;
  my $join = ' ';
  foreach my $p (@$points) {
    my ($x,$y) = @$p;
    my $x_str = $x;
    my $y_str = $y;
    printwrap("$join($x_str,$y_str)");
    $join = '--';
  }
  printwrap("${join}cycle");
}


1;
__END__
