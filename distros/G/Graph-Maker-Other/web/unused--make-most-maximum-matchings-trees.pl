#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use FindBin;
use File::chdir;
use File::Slurp;
use File::Spec;
use File::stat;
use Image::Base::GD;
use IPC::Run;
use List::Util 'min','max';
$|=1;

my $libdir;
BEGIN { $libdir = File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'lib'); }
use lib $libdir;
use Graph::Maker::MostMaximumMatchingsTree;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# HOG Links

my $HOG_base_url = 'https://hog.grinvin.org';
my %N_to_HOG;

{
  my $content = File::Slurp::read_file
    (File::Spec->catfile($libdir,'Graph','Maker',
                         'MostMaximumMatchingsTree.pm'));
  $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
  $content = $&;
  my $count = 0;
  while ($content =~ /^ +(?<ids>(\d+, )*\d+) +N=(?<Nlo>[0-9.]+)( to N=(?<Nhi>[0-9]+))?/mg) {
    $count++;
    my $ids = $+{'ids'};
    my $Nlo = $+{'Nlo'};
    my $Nhi = $+{'Nhi'} // $Nlo;
    my @ids = split /, /, $ids;
    ### match: "$ids  $Nlo $Nhi"
    for (my $N = $Nlo; $N <= $Nhi; $N++) {
      @ids or die;
      my $id = shift @ids;
      if (defined $N_to_HOG{$N}) { die "oops, duplicate"; }
      $N_to_HOG{$N} = $id;
    }
    @ids==0 or die "oops";    
  }
}


#------------------------------------------------------------------------------
# Gallery Images

my $n_lo = 0;
my $n_hi = 90;

my $background_colour = 'black';
my $line_colour       = 'white';
sub n_to_vertex_colour {
  my ($n) = @_;
  if ($n < 21) { return '#FF0000'; }
  if ($n >= 170) { return '#FF0000'; }
  return 'white';
}

sub n_to_width {
  my ($n) = @_;
  if ($n == 181) { return 280; }
  if ($n >= 170) { return 250; }
  return 89;
}
sub n_to_height {
  my ($n) = @_;
  if ($n < 70) { return 67; }
  if ($n >= 170) { return 200; }
  return 85;
}
sub n_to_scale {
  my ($n) = @_;
  if ($n < 7) { return 14; }
  if ($n < 14) { return 8; }
  if ($n < 35) { return 6; }
  if ($n < 49) { return 4; }
  return 3;
}

sub Graph_vertex_xy {
  my ($graph,$v) = @_;
  return ($graph->get_vertex_attribute($v,'x'),
          $graph->get_vertex_attribute($v,'y'));
}
sub Graph_bbox {
  my ($graph) = @_;
  my @vertices = $graph->vertices;
  my @x = map {$graph->get_vertex_attribute($_,'x')} @vertices;
  my @y = map {$graph->get_vertex_attribute($_,'y')} @vertices;
  unless (@x) { push @x, 0; }
  unless (@y) { push @y, 0; }
  return (min(@x),min(@y), max(@x),max(@y));
}

# add text to the png image in $filename
sub pngtextadd {
  my ($filename, $keyword, $value) = @_;
  system('pngtextadd', "--keyword=$keyword", "--text=$value", $filename) == 0
    or die "system(pngtextadd)";
}

my $program_filename = File::Spec->catfile($FindBin::Bin,
                                           $FindBin::Script);
my $copyright = File::Slurp::read_file($program_filename);
$copyright =~ /^# (Copyright.*)/m or die;
$copyright = $1;

# PNG spec 11.3.4.2 suggests RFC822 (or rather RFC1123) for CreationTime
use constant STRFTIME_FORMAT_RFC822 => '%a, %d %b %Y %H:%M:%S %z';
my $stat = File::stat::stat($program_filename)
  or die "Oops, cannot stat $program_filename: $!";
my $creation_time = POSIX::strftime(STRFTIME_FORMAT_RFC822,
                                    localtime($stat->mtime));

{
  my $count = 0;
  my $total_size = 0;

  my $make_png = sub {
    my ($n, %options) = @_;
    my $filename = "MostMaximumMatchingsTree-$n.png";
    my $graph = Graph::Maker->new ('most_maximum_matchings_tree',
                                   N => $n,
                                   coordinate_type => 'HW',
                                   undirected=>1);
    my ($x_min,$y_min, $x_max,$y_max) = Graph_bbox($graph);
    my $x_mid = ($x_min + $x_max) / 2;
    my $y_mid = ($y_min + $y_max) / 2;

    my $width  = n_to_width($n);
    my $height = n_to_height($n);
    my $width_mid = ($width+1)>>1;
    my $height_mid = ($height+1)>>1;

    my $image = Image::Base::GD->new (-height => $height,
                                      -width  => $width);
    $image->rectangle(0,0, $width-1,$height-1, $background_colour);

    my $scale = $options{'scale'} // n_to_scale($n);
    my $transform = sub {
      my ($x,$y) = @_;
      $x -= $x_mid;
      $y -= $y_mid;
      $x *= $scale;
      $y *= $scale;
      $x += $width_mid;
      $y += $height_mid;
      $y = $height-1 - $y;  # up the screen

      $x>=0 or warn "x = $x negative at n=$n";
      $y>=0 or warn "y = $y negative at n=$n";
      $x<$width or warn "x = $x too big at n=$n";
      $y<$height or warn "y = $y too big at n=$n";
      return ($x,$y);
    };

    foreach my $edge ($graph->edges) {
      my ($v1,$v2) = @$edge;
      $image->line($transform->(Graph_vertex_xy($graph,$v1)),
                   $transform->(Graph_vertex_xy($graph,$v2)),
                   $line_colour);
    }

    my $vertex_colour = n_to_vertex_colour($n);
    foreach my $v ($graph->vertices) {
      $image->xy($transform->(Graph_vertex_xy($graph,$v)),
                 $vertex_colour);
    }

    $image->save($filename);

    pngtextadd($filename, 'Author',    'Kevin Ryde');
    pngtextadd($filename, 'Generator', "web/$FindBin::Script");
    pngtextadd($filename, 'Title',     "Most Maximum Matchings Tree $n");
    pngtextadd($filename, 'Creation Time', $creation_time);
    pngtextadd($filename, 'Copyright', $copyright);
    pngtextadd($filename, 'Homepage',  'http://user42.tuxfamily.org/graph-maker-other/index.html');

    my $uncompressed_size = -s $filename;
    require IPC::Run;
    IPC::Run::run(['optipng','-quiet','-o5',$filename]);
    my $size = -s $filename;
    # print "compressed $uncompressed_size to $size\n";
    $count++;
    $total_size += $size;
  };


  foreach my $n ($n_lo .. $n_hi) {
    $make_png->($n);
  }
  $make_png->(177, scale => 7);
  $make_png->(181, scale => 7);

  print "$count .png files total size $total_size\n";
}


#------------------------------------------------------------------------------
# Gallery HTML

{
  my $html_filename = '/tmp/gallery.html';
  open my $fh, '>', $html_filename or die;
  print $fh "<!-- Generated by $FindBin::Script -->\n";
  foreach my $n ($n_lo .. $n_hi) {
    my $width = n_to_width($n);
    my $height = n_to_height($n);
    if ($n%7==0) {
      print $fh "<tr align=center>\n";
    }
    my $hog = '';
    if (defined(my $id = $N_to_HOG{$n})) {
      $hog = ", <a href=\"$HOG_base_url/ViewGraphInfo.action?id=$id\">HoG</a>";
    }
    print $fh <<"HERE";
<td>
  <img src="MostMaximumMatchingsTree-$n.png" width=$width height=$height
       alt="tree $n">
  <br>
  n=$n$hog
</td>
HERE
    if ($n%7==6) {
      print $fh "</tr>\n";
    }
  }
  print $fh "<!-- End generated -->\n";
  close $fh or die $!;

  print "$html_filename size ",-s $html_filename,"\n";
}

#------------------------------------------------------------------------------
# MostMaximumMatchingsTrees.s6

if (0) {
  my $sparse6_filename = 'MostMaximumMatchingsTrees.s6';
  if (-e $sparse6_filename) {
    unlink $sparse6_filename or die "Cannot remove $sparse6_filename: $!";
  }
  my $gp_writefile = gp_string_escape(File::Spec->rel2abs
                                      (File::Spec->catfile
                                       ($FindBin::Bin, $sparse6_filename)));
  my $prog = <<"HERE";
{
  for(n=1,255,
      my(vpar=make(n));
      write("$gp_writefile",vpar_to_sparse6(vpar)));
}
HERE
  ### $prog
  my $outstr;
  {
    local $CWD = '../../vpar/examples';
    IPC::Run::run([ 'gp', '-f', 'most-maximum-matchings.gp' ],
                  '<',\$prog,
                  '>',\$outstr)
        or die "gp: $?";
  }
  print "$sparse6_filename size ",-s $sparse6_filename,"\n";
}

sub gp_string_escape {
  my ($str) = @_;
  $str =~ s/["\\]/\\$&/g;
  return $str;
}
CHECK {
  gp_string_escape('""') eq '\\"\\"' or die;
}

#------------------------------------------------------------------------------
exit 0;
