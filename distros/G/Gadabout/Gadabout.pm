package Gadabout;

use strict;
use POSIX;

use vars qw/$VERSION/;

$VERSION = '1.0001';

#Constructor Class
#
sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    if($class eq __PACKAGE__) {
        my $implementation = shift || 'Imlib2';
        my $iclass = $class.'::'.$implementation;
        eval "use $iclass;";
        if($@) {
            die "Unable to find $iclass: $@";
        }
        $self = bless {}, $iclass;
        $self = $self->new();
    } else {
        $self = bless {}, $class;
    }
    $self;
}

#Begin Virtual classes
#

sub InitImage{
  die "Virtual function";
}

sub DrawLine{
  die "Virtual function";
}

sub DrawDashedLine{
  die "Virtual function";
}

sub DrawPolygon{
  die "Virtual function";
}

sub DrawFilledPolygon{
  die "Virtual function";
}

sub DrawRectangle{
  die "Virtual function";
}

sub DrawGradientRectangle{
  die "Virtual function";
}

sub DrawFilledRectangle{
  die "Virtual function";
}

sub AddFontPath {
  die "Virtual function";
}

sub SetFont {
  die "Virtual function";
}

sub DrawText{
  die "Virtual function";
}

sub DrawImage{
  die "Virtual function";
}

sub DrawEllipse{
  die "Virtual function";
}

sub DrawBrush{
  die "Virtual function";
}

sub GetTextSize{
  die "Virtual function";
}

#
#  End Virtual Classes



sub InitGraph{
  my $self = shift;
  my $width = shift;
  my $height = shift;

  $self->{num_data_sets} = 0;

  $self->{perLegendHeight} = 30;

  $self->{xpad} = 70;
  $self->{ypad} = 50;

  $self->{image_height} = $height;
  $self->{image_width}  = $width;

  $self->SetGraphSize();

  $self->InitImage();

  $self->{xAxisSpacing} = 50;
  $self->{yAxisSpacing} = 50;

  $self->{vBarWidth}    = 7; #for bar charts

  $self->{xTickPadding}  = 8;
  $self->{yTickPadding}  = 8; 
  $self->{yTitlePadding} = 5;

  $self->{polygon_max_verts} = 2;

  $self->CreateColor("white"     , 255, 255, 255, 255);
  $self->CreateColor("black"     , 0  , 0  , 0  , 255);
  $self->CreateColor("red"       , 220, 0  , 0  , 200);
  $self->CreateColor("lightred"  , 255, 150, 150, 200);
  $self->CreateColor("blue"      , 0  , 0  , 220, 200);
  $self->CreateColor("lightblue" , 0  , 0  , 220, 125);
  $self->CreateColor("darkgray"  , 120, 120, 120, 200);
  $self->CreateColor("gray"      , 180, 180, 180, 200);
  $self->CreateColor("magenta"   , 240, 0  , 240, 200);
  $self->CreateColor("yellow"    , 240, 240, 0  , 200);
  $self->CreateColor("green"     , 0  , 140, 0  , 200);
  $self->CreateColor("lightgreen", 0  , 140, 0  , 125);
} # sub InitGraph



sub SetGraphSize{
  my $self = shift;
  my $noLegend = shift;
  $noLegend = 0 if (!defined($noLegend));
  if (!$self->{noLegend}) {
    $self->{legendHeight} = $self->{perLegendHeight} * ($self->{num_data_sets} + 1);
  } else {
    $self->{legendHeight} = 0;
  }

  $self->{graph_height} = $self->{image_height} - (2 * $self->{ypad}) - $self->{legendHeight};
  $self->{graph_width}  = $self->{image_width}  - (2 * $self->{xpad});
} # sub SetGraphSize


sub CreateColor{
  my $self = shift;
  my $name = shift;
  my $red = shift;
  my $green = shift;
  my $blue = shift;
  my $alpha = shift;
  $alpha = 125 if (!defined($alpha));
  if (($red >= 0) && ($red <= 255) && ($blue >= 0) && ($blue <= 255) &&($green >= 0) && ($green <= 255)) {
    $self->{color}{$name} = {"red" => $red, "blue" => $blue, "green" => $green, "alpha" => $alpha};
    $self->{color}{"translucent-" . $name} = {"red" => $red, "blue" => $blue, "green" => $green, "alpha" => $self->min(30,floor($alpha / 2))};
    return $name;
  }
  else {
    return 0;
  }
} # sub CreateColor


sub SetTitle{
  my $self = shift;
  my $title = shift;
  my $titleSize = $self->GetTextSize($title,0);
  my $text_left = ($self->{image_width} / 2) - ($titleSize->{"width"} / 2);

  $self->DrawText($self->{font},$text_left,5,$title,"black",0);
} # sub SetTitle


sub SetSubTitle{
  my $self = shift;
  my $subtitle = shift;
  my $titleSize = $self->GetTextSize($subtitle,0);
  my $text_left = ($self->{image_width} / 2) - ($titleSize->{"width"} / 2);

  $self->DrawText($self->{font},$text_left,25,$subtitle,"black",0);
} # sub SetTitle


sub SetxTitle{
  my $self = shift;
  my $xtitle = shift;
  $self->{xTitle} = $xtitle;
} # sub SetxTitle


sub SetyTitle{
  my $self = shift;
  my $ytitle = shift;
  $self->{yTitle} = $ytitle;
} # sub SetyTitle


sub SetAxis2Title{
  my $self = shift;
  my $title = shift;
  $self->{axis2Title} = $title;
} # sub SetAxis2Title


sub AddData{
  my ($self, $xdata, $ydata, $name) = @_;
  $name = "" if (!defined($name));

  $self->SetGraphSize($self->{image_height},$self->{image_width});
  $self->{legendText}[$self->{num_data_sets}] = $name;

  #sort(@xdata);

  my $dataSetIndex = $self->{num_data_sets};
  for (my $i=0; $i < @$xdata; $i++){
    $self->{data_set}[$dataSetIndex]{"x"}[$i] = $xdata->[$i];
    $self->{data_set}[$dataSetIndex]{"y"}[$i] = $ydata->[$i];
  }

  my $XSize = @$xdata;
  my $YSize = @$ydata;
  $self->{num_points}[$self->{num_data_sets}] = $self->min($XSize, $YSize);

  if ($self->{num_data_sets} == 0) {
    $self->{xmax} = $self->ArrayMax($xdata);
    $self->{xmin} = $self->ArrayMin($xdata);
  }
  else {
    my $tmp_xmax = $self->ArrayMax($xdata);
    my $tmp_xmin = $self->ArrayMin($xdata);

    $self->{xmax} = $self->max($self->{xmax},$tmp_xmax);
    $self->{xmin} = $self->min($self->{xmin},$tmp_xmin);
  }

  $self->{xdata_diff} = $self->{xmax} - $self->{xmin};

  if (!$self->{xdata_diff}) {
    $self->{xdata_diff} = 5;
  }

  if (!$self->{use_axis2}) {
    if ($self->{num_data_sets} == 0) {
      $self->SetYMax($self->ArrayMax($ydata));
      $self->SetYMin($self->ArrayMin($ydata));
    } else {
      my $tmp_ymax = $self->ArrayMax($ydata);
      my $tmp_ymin = $self->ArrayMin($ydata);

      $self->SetYMax($self->max($self->{ymax},$tmp_ymax));
      $self->SetYMin($self->min($self->{ymin},$tmp_ymin));
    }

    if ($self->{ymax} == $self->{ymin}) {
      $self->{ydata_diff} = 10;
      $self->SetYMax($self->{ymin} + $self->{ydata_diff});
    } else {
      $self->{ydata_diff} = $self->{ymax} - $self->{ymin};
    }
  }
  else {
    $self->{axis2_data}[$self->{num_data_sets}] = 1;

    if (!defined(%{$self->{axis2}})) {
      $self->{axis2}{"ymax"} = $self->ArrayMax($ydata);
      $self->{axis2}{"ymin"} = $self->ArrayMin($ydata);
    }
    else {
      my $tmp_ymax = $self->ArrayMax($ydata);
      my $tmp_ymin = $self->ArrayMin($ydata);

      $self->{axis2}{"ymax"} = $self->max($self->{axis2}{"ymax"},$tmp_ymax);
      $self->{axis2}{"ymin"} = $self->min($self->{axis2}{"ymin"},$tmp_ymin);
    }

    if ($self->{axis2}{"ymax"} == $self->{axis2}{"ymin"}) {
      $self->{axis2}{"ydata_diff"} = 10;
      $self->{axis2}{"ymax"}       = $self->{axis2}{"ymin"} + $self->{axis2}{"ydata_diff"};
    } else {
      $self->{axis2}{"ydata_diff"} = $self->{axis2}{"ymax"} - $self->{axis2}{"ymin"};
    }

    $self->{show_axis2} = 1;
  }

  $self->{num_data_sets}++;
  return $self->{num_data_sets}-1;
} # sub AddData


sub DrawGrid{
  my $self = shift;
  my $color = shift;
  my $numGrid  = 10;

  my $xNum     = $self->{graph_width}  / $self->{xAxisSpacing};
  my $yNum     = $self->{graph_height} / $self->{yAxisSpacing};

  my $numxGrid = int($self->min($numGrid, $xNum)+.5);
  my $numyGrid = int($self->min($numGrid, $yNum)+.5);

  my $xIntOnly;
  if (defined($self->{xLabel})) {
    $xIntOnly = 1;
  } else {
    $xIntOnly = 0;
  }

  my $yTick;
  if (!defined($self->{yTick})) {
    $yTick = $self->adjustNum(($self->{ydata_diff} / $numyGrid), $self->{ydata_diff}, $numyGrid);
  }
  else {
    $yTick = $self->{yTick};
  }

  my $xTick;
  if (!defined($self->{xTick})) {
    $xTick = $self->adjustNum(($self->{xdata_diff} / $numxGrid), $self->{xdata_diff}, $numxGrid,$xIntOnly);
  }
  else {
    $xTick = $self->{xTick};
  }

  my $xLabelYMod = 6;

  my $xStart = (defined($xTick) ? floor($self->{xmin} / $xTick) : $self->{xmin});
  my $xEnd   = (defined($xTick) ? ceil($self->{xmax} / $xTick) : $self->{max});

  my $yStart = (defined($yTick) ? floor($self->{ymin} / $yTick) : $self->{ymin});
  my $yEnd   = (defined($yTick) ? ceil($self->{ymax} / $yTick) : $self->{ymax});

  $self->SetYMin($yStart * $yTick);
  $self->SetYMax($yEnd * $yTick);

  $self->SetXMin($xStart * $xTick);
  $self->SetXMax($xEnd * $xTick);

  my $xfoo = $self->{xmax} - $xTick;
  my $yfoo = $self->{ymax} - $yTick;

  my ($im_xmax, $im_ymax) = $self->translate($self->{xmax},$self->{ymax});

  my $axis2_ytick;
  if ($self->{show_axis2}) {
    if (!defined($self->{axis2_ytick})) {
      $axis2_ytick = $self->adjustNum(($self->{axis2}{"ydata_diff"} / $numyGrid), $self->{axis2}{"ydata_diff"}, $numyGrid);
    } else {
      $axis2_ytick = $self->{axis2_ytick};
    }
    my $min2_decimal = ceil((floor($self->{axis2}{"ymin"}) - $self->{axis2}{"ymin"}) / $axis2_ytick) * $axis2_ytick;
    my $max2_decimal = floor((floor($self->{axis2}{"ymax"}) - $self->{axis2}{"ymax"}) / $axis2_ytick) * $axis2_ytick;

    my $newYmin = floor($self->{axis2}{"ymin"}) - $min2_decimal;
    my $newYmax = $newYmin + ($axis2_ytick * ($yEnd - $yStart));

    $self->SetYMin($newYmin,1);
    $self->SetYMax($newYmax,1);
  }
  else {
    $axis2_ytick = 0;
  }

  for (my $gridCount = $xStart; $gridCount <= $xEnd; ++$gridCount) {
    my $gridx       = $gridCount * $xTick;
    $xLabelYMod = $xLabelYMod * -1;

    my ($x0, $y0) = $self->translate($gridx,$self->{ymin});
    $self->GraphDashedLine($gridx, $self->{ymin}, $gridx, $self->{ymax}, 2, 3, $color);

    $self->DrawLine($x0, $y0 + 9 + $xLabelYMod, $x0, $y0 - 3, "black");

    my $gridLabel;
    if ($self->{xLabel}) {
      $gridLabel = $self->{xLabel}[$gridx];
    }
    else {
      $gridLabel = $gridx;
    }

    my $gridLabelSize = $self->GetTextSize($gridLabel,0);

    $self->DrawText($self->{font},$x0 - ($gridLabelSize->{"width"} / 2),$y0 + 10 + $xLabelYMod,$gridLabel,"black",0);
    my $lastdrawn = $xLabelYMod;
  }


  for (my $gridCount = $yStart; $gridCount <= $yEnd; $gridCount++) {
    my $gridy = $gridCount * $yTick;

    my ($x0, $y0) = $self->translate($self->{xmin},$gridy);
    $self->GraphDashedLine($self->{xmin}, $gridy, $self->{xmax}, $gridy, 2, 3, $color);

    $self->DrawLine($x0 - 3, $y0, $x0 + 3, $y0, "black");

    if (defined($axis2_ytick)) {
      $self->DrawLine($im_xmax - 3, $y0, $im_xmax + 3, $y0, "black");
    }

    my $strSize           = $self->GetTextSize($gridy,0);
    $self->{axis1Padding} = $self->max($self->{axis1Padding},$strSize->{width});

    $self->DrawText($self->{font},$x0 - $strSize->{"width"} - $self->{xTickPadding},$y0 - ($strSize->{"height"} / 2),$gridy,"black",0);

    if (defined($axis2_ytick) && ($axis2_ytick != 0)) {
      my $axis2_gridy = ($gridCount - $yStart) * $axis2_ytick + $self->{axis2}{"ymin"};
      my $strSize            = $self->GetTextSize($axis2_gridy,0);
      $self->{axis2Padding} = $self->max($self->{axis2Padding},$strSize->{"width"});

      $self->DrawText($self->{font},$im_xmax + $self->{xTickPadding},$y0 - ($strSize->{"height"} / 2),$axis2_gridy,"black",0);
      $self->{axis2LegendPad} = $self->max($self->{axis2LegendPad},length($axis2_gridy));
    }
  }

  $self->DrawLine($im_xmax-1, $im_ymax, $im_xmax, $im_ymax, $color);
  $self->DrawLine($im_xmax, $im_ymax+1, $im_xmax, $im_ymax, $color);
} # sub DrawGrid


sub LineGraph{
  my ($self, $dataset, $color) = @_;

  $self->{current_dataset} = $dataset;
  $self->{legend}{$dataset}{'LineGraph'} = {"color" => $color};

  my $lastx = $self->{data_set}[$dataset]{"x"}[0];
  my $lasty = $self->{data_set}[$dataset]{"y"}[0];
		
  for (my $i = 1; $i < $self->{num_points}[$dataset]; $i++) {
    $self->GraphLine($lastx, $lasty, $self->{data_set}[$dataset]{"x"}[$i], $self->{data_set}[$dataset]{"y"}[$i], $color);
    $lastx = $self->{data_set}[$dataset]{"x"}[$i];
    $lasty = $self->{data_set}[$dataset]{"y"}[$i];
  }

} #sub LineGraph


sub FilledLineGraph{
  my $self = shift;
  my $dataset = shift;
  my $color = shift;

  $self->{current_dataset} = -1;
  my $min = $self->min($self->{ymin}, $self->{axis2}{ymin});

  my ($graph_left, $graph_bottom) = $self->translate($self->{xmin},$min);

  $self->{current_dataset} = $dataset;
  $self->{legend}{$dataset}{'FilledLineGraph'} = {'color' => $color};

  my ($last_x, $last_y) = $self->translate($self->{data_set}[$dataset]{"x"}[0],$self->{data_set}[$dataset]{"y"}[0]);
  $graph_bottom = int($graph_bottom+.5);
  my $first_x  = int($last_x+.5);
  my $first_y  = int($last_y+.5);

  my %graphed;
  my @verts;

  $verts[0] = {"x" => $first_x, "y" => $first_y};
  $graphed{$first_x . "," . $first_y} = 1;

  my $this_x;
  my $this_y;

  for (my $i=0; $i < $self->{num_points}[$dataset]; $i++) {
   ($this_x, $this_y) = $self->translate($self->{data_set}[$dataset]{"x"}[$i],$self->{data_set}[$dataset]{"y"}[$i]);

    $this_x = int($this_x+.5);
    $this_y = int($this_y+.5);

    if (!scalar(@verts)) {
      my $slope   = ($this_y - $last_y) / ($this_x - $last_x);
      $first_x = $last_x + 1;
      $first_y = $last_y + int($slope+.5);

      $verts[0]  = {"x" => $first_x, "y" => $first_y};
      $graphed{$first_x . "," . $first_y} = 1;
    }

    if (!defined($graphed{$this_x . "," . $this_y})) {
      push(@verts, {"x" => $this_x, "y" => $this_y});
      $graphed{$this_x . "," . $this_y} = 1;
    }

    if ($i % $self->{polygon_max_verts} == 0) {
      if (!defined($graphed{$this_x . "," . $graph_bottom})) {
        push(@verts,{"x" => $this_x, "y" => $graph_bottom});
        $graphed{$this_x . "," . $graph_bottom} = 1;
      }

      if (!defined($graphed{$first_x . "," . $graph_bottom})) {
        push(@verts,{"x" => $first_x , "y" => $graph_bottom});
        $graphed{$first_x . "," . $graph_bottom} = 1;
      }

      $self->DrawFilledPolygon(\@verts,$color);

      $last_x = $this_x;
      $last_y = $this_y;

      %graphed = ();
      @verts = ();
    }
  }

  if (!defined($graphed{$this_x . "," . $graph_bottom})) {
    push(@verts, {"x" => $this_x, "y" => $graph_bottom});
    $graphed{$this_x . "," . $graph_bottom} = 1;
  } 

  if (!defined($graphed{$first_x . "," . $graph_bottom})) {
    push(@verts,{"x" => $verts[0]{"x"} , "y" => $graph_bottom});
    $graphed{$first_x . "," . $graph_bottom} = 1;
  }

  if (scalar(@verts) > 3) {
    $self->DrawFilledPolygon(\@verts,$color);
  }
} # sub FilledLineGraph


sub DrawLegend{
  my $self = shift;

  if (defined($self->{legend})) { 
    my $legend_top  = $self->{graph_height} + 2 * $self->{ypad};
    my $current_top = $legend_top;

    $self->DrawText($self->{font},10,$legend_top - 18,"Legend:","black",0);
    $self->DrawLine(10,$legend_top - 4,47,$legend_top - 4,"black");

    my $dataset;
    my $type;
    my $datasetInfo;
    my $legendInfo;
    my $tmpHash = $self->{legend};
    while (($dataset, $legendInfo) = each %$tmpHash) {
      my $legend_left = 10;
      while(($type, $datasetInfo) = each %$legendInfo) {
        my $legendMod;
        if (exists($legendInfo->{'FilledLineGraph'}) || exists($legendInfo->{'VBarGraph'})) {
          $legendMod = 0;
        } else {
          $legendMod = 8;
        }

        if ($type eq "FilledLineGraph"){
          $self->DrawFilledRectangle($legend_left,$current_top,15,15,$datasetInfo->{"color"});
        }
        else{
          if ($type eq "DashedLineGraph"){
            $self->DrawDashedLine($legend_left,$current_top + $legendMod, $legend_left + 15, $current_top + $legendMod, 3, 4, $datasetInfo->{"color"});
          }
          else{
            if ($type eq "ScatterGraph"){
              $self->DrawBrush($legend_left + 8,$current_top + $legendMod,$datasetInfo->{'shape'},$datasetInfo->{"color"});
            }
            else{
              if ($type eq "LineGraph"){
                $self->DrawLine($legend_left,$current_top + $legendMod, $legend_left + 15, $current_top + $legendMod, $datasetInfo->{"color"});
              }
              else{
                if ($type eq "VBarGraph"){
                  $self->DrawGradientRectangle($legend_left + (15 - $self->{vBarWidth}) / 2, $current_top , $self->{vBarWidth}, 15, $datasetInfo->{"color"});
                }
              }
            }
          }
        }
      }
      my $mesg;
      if (defined($self->{axis2_data}[$dataset])) {
        $mesg = " (Right Hand Scale)";
      } else {
        $mesg = "";
      }

      $legend_left += 20;
      my $label;
      if (defined($self->{legendText}[$dataset])){
        $label = $self->{legendText}[$dataset];
      }
      else{
        $label = "Dataset: " . $dataset;
      }
      $label = $label . $mesg;
      $self->DrawText($self->{font}, $legend_left, $current_top, $label, "black", 0);
      $current_top += 20;
      #$dataset++;
    }
  }
} #sub DrawLegend



sub DrawAxis{
  my $self = shift;
  $self->{current_dataset} = 0;

  $self->GraphLine($self->{xmin},$self->{ymin},$self->{xmax},$self->{ymin},"black");
  $self->GraphLine($self->{xmin},$self->{ymin},$self->{xmin},$self->{ymax},"black");

  if ($self->{show_axis2}) {
    $self->GraphLine($self->{xmax},$self->{ymin},$self->{xmax},$self->{ymax},"black");
  }

  $self->DrawxTitle();
  $self->DrawyTitle();

  if ($self->{show_axis2}) {
    $self->DrawAxis2Title();
  }

  $self->DrawLegend();
} # sub DrawAxis


sub showDebug{
  my $self = shift;
  my $i = 0;
  foreach my $k ($self->{strDebug}) {
    $self->DrawText($self->{font},5,10 * (++$i) - 5,$k,"black",0);
  }
} # sub showDebug


sub ShowGraph{
  my $self = shift;
  $self->showDebug();
  header ("Expires: 0");    # Date in the past
  header ("Cache-Control: no-cache, must-revalidate");  # HTTP/1.1
  header ("Pragma: no-cache");                          # HTTP/1.0
  $self->DrawImage();
} # sub ShowGraph


sub translateX{
  my $self = shift;
  my $xIn = shift;
  my $xdata_diff = $self->{xdata_diff};
  my $xmin       = $self->{xmin};

  if ($xdata_diff) {
    return ($self->{graph_width} / $xdata_diff) * ($xIn - $xmin) + $self->{xpad};
  }
} # sub translateX



sub translateY{
  my $self = shift;
  my $yIn = shift;
  my $ydata_diff;
  my $ymax;
   
  if (defined($self->{axis2_data}[$self->{current_dataset}]) || $self->{draw_axis2}) {
    $ydata_diff = $self->{axis2}{"ydata_diff"};
    $ymax       = $self->{axis2}{"ymax"};
  }
  else {
    $ydata_diff = $self->{ydata_diff};
    $ymax       = $self->{ymax};
  }

  if ($ydata_diff) {
    return ((($ymax - $yIn) / $ydata_diff) * $self->{graph_height}) + $self->{ypad};
  }
} #sub translateY



sub translate{
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $xpos = $self->translateX($x,"points");
  my $ypos = $self->translateY($y,"points");
  return ($xpos, $ypos);
} # sub translate



sub adjustNum{
  my $self = shift;
  my $num = shift;
  my $data_diff = shift;
  my $num_divisions = shift;
  my $integers = shift;
  if (!defined($integers)){
    $integers = 0;
  }
  
  $data_diff = abs($data_diff);
  my $adjusted  = $data_diff / $num_divisions;

  if ($adjusted >= 1) {
    my $decimals = floor(log10($num));
    my $divisor  = 10**$decimals;
    $num      = ceil($num / $divisor) * $divisor;
  } else {
    my $decimals = floor(log10($num));
    my $divisor  = 10**$decimals;
    $num      =   int(($num / $divisor)+.5) * $divisor;

    my $newnum = $num;

    if ($num >= .2) {
      $newnum = .25;
    }

    if ($num >= .5) {
      $newnum = .5;
    }

    if ($num >= .7) {
      $newnum = 1;
    }

    $num = $newnum;
  }

  if ($integers) {
    $num = $self->max(ceil($num),1);
  }
  return $num;
} # sub adjustNum


sub SetYMin{
  my $self = shift;
  my $ymin = shift;
  my $axis2 = shift;
  $axis2 = 0 if (!defined($axis2));

  if (!$axis2) {
    if (defined($self->{ymin})) {
      $self->{ymin} = $self->min($ymin,$self->{ymin});
    } else {
      $self->{ymin} = $ymin + 0;
    }
    $self->{ydata_diff} = $self->{ymax} - $self->{ymin};
  }
  else {
    if (defined($self->{axis2}{"ymin"})) {
      $self->{axis2}{"ymin"} = $self->min($ymin,$self->{axis2}{"ymin"});
    } else {
      $self->{axis2}{"ymin"} = $ymin;
    }
    $self->{axis2}{"ydata_diff"} = $self->{axis2}{"ymax"} - $self->{axis2}{"ymin"};
  }
} # sub SetYmin



sub SetYMax{
  my $self = shift;
  my $ymax = shift;
  my $axis2 = shift;
  $axis2 = 0 if (!defined($axis2));

  if (!$axis2) {
    if (defined($self->{ymax})) {
      $self->{ymax} = $self->max($ymax,$self->{ymax});
    } else {
      $self->{ymax} = $ymax + 0;
    }

    $self->{ydata_diff} = $self->{ymax} - $self->{ymin};
    } else {
      if (defined($self->{axis2}{"ymax"})) {
        $self->{axis2}{"ymax"} = $self->max($ymax,$self->{axis2}{"ymax"});
      } else {
        $self->{axis2}{"ymax"} = $ymax + 0;
      }

      $self->{axis2}{"ydata_diff"} = $self->{axis2}{"ymax"} - $self->{axis2}{"ymin"};
  }
} # sub SetYmax



sub SetXMin{
  my $self = shift;
  my $xmin = shift;

  if (defined($self->{xmin})) {
    $self->{xmin} = $self->min($xmin,$self->{xmin});
  } else {
    $self->{xmin} = $xmin + 0;
  }

  $self->{xdata_diff} = $self->{xmax} - $self->{xmin};
} # sub SetXmin



sub SetXMax($xmax) {
  my $self = shift;
  my $xmax = shift;

  if (defined($self->{xmax})) {
    $self->{xmax} = $self->max($xmax,$self->{xmax});
  } else {
    $self->{xmax} = $xmax + 0;
  }

  $self->{xdata_diff} = $self->{xmax} - $self->{xmin};
} # sub SetXmax


sub GraphLine{
  my $self = shift;
  my $x1 = shift;
  my $y1 = shift;
  my $x2 = shift;
  my $y2 = shift;
  my $color = shift;

  my ($x1pos, $y1pos) = $self->translate($x1,$y1);
  my ($x2pos, $y2pos) = $self->translate($x2,$y2);

  $self->DrawLine($x1pos,$y1pos,$x2pos,$y2pos,$color);
} # sub GraphLine



sub GraphDashedLine{
  my $self = shift;
  my $x1 = shift;
  my $y1 = shift;
  my $x2 = shift;
  my $y2 = shift;
  my $dash_length = shift;
  my $dash_space = shift;
  my $color = shift;
	
  my ($x1pos, $y1pos) = $self->translate($x1,$y1);
  my ($x2pos, $y2pos) = $self->translate($x2,$y2);

  $self->DrawDashedLine($x1pos,$y1pos,$x2pos,$y2pos,$dash_length,$dash_space,$color);
} # sub GraphDashedLine



sub DrawxTitle{
  my $self = shift;
  my $titleSize = $self->GetTextSize($self->{xTitle},0);
  my $text_left = ($self->{image_width} / 2) - ($titleSize->{"width"} / 2);

  $self->DrawText($self->{font},$text_left,($self->{graph_height} + $self->{ypad} + 35),$self->{xTitle},"black",0);
} # sub DrawxTitle



sub DrawyTitle{
  my $self = shift;
  my $titleSize = $self->GetTextSize($self->{yTitle},3);
  my $text_left = $self->{xpad} - $self->{axis1Padding} - $self->{xTickPadding} - $titleSize->{"width"} - $self->{yTitlePadding};

  my $text_top  = (($self->{graph_height} + 2 * $self->{ypad}) / 2) - (length($self->{yTitle}) * 2.4);
  $self->DrawText($self->{font},$text_left,$text_top,$self->{yTitle},"black",3);
}


sub DrawAxis2Title{
  my $self = shift;
  my $titleSize = $self->GetTextSize($self->{axis2Title},2);

  my $text_left = $self->{image_width} - $self->{xpad} + $self->{axis2Padding} + $self->{xTickPadding} + ($titleSize->{"width"} / 2);
  my $text_top  = (($self->{graph_height} + 2 * $self->{ypad}) / 2) - ($titleSize->{"height"}/ 2);

  $self->DrawText($self->{font},$text_left,$text_top,$self->{axis2Title},"black",2);
}


sub SetYTick{
  my $self = shift;
  my $yTick = shift;
  $self->{yTick} = $yTick;
} #sub SetYTick



sub SetAxis2Tick{
  my $self = shift;
  my $axis2_ytick = shift;
  $self->{axis2_ytick} = $axis2_ytick;
} #sub SetYTick



sub SetXTick{
  my $self = shift;
  my $xTick = shift;
  $self->{xTick} = $xTick;
} #sub SetXTick


sub GraphBrush{
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $shape = shift;
  my $color = shift;

  my ($xpos, $ypos) = $self->translate($x,$y);
  $self->DrawBrush($xpos,$ypos,$shape,$color);
} #sub GraphBrush


sub GraphVBar{
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $color = shift;
  my $xshift = shift;
  if (!defined($xshift)){
   $xshift = 0;
  }
  my ($xpos, $ypos) = $self->translate($x,$y);
  my ($xminpos, $yminpos) = $self->translate($self->{xmin},$self->{ymin});

  my $width     = $self->{vBarWidth};
  my $height    = abs($ypos - $yminpos);
  $xpos         = $xpos + $xshift;

  $self->DrawGradientRectangle($xpos - floor($width / 2), $ypos, $width, $height, $color);
} #sub GraphVBar


sub SetGridLabel{
  my $self = shift;
  my $labels = shift;
  my $axis = shift;
  if ($axis eq "x") {
    $self->{xLabel} = $labels;
  } else {
    $self->{yLabel} = $labels;
  }
} 

sub SetXGridLabel{
  my $self = shift;
  my $labels = shift;
  $self->SetGridLabel($labels,"x");
}

sub SetYGridLabel{
  my $self = shift;
  my $labels = shift;
  $self->SetGridLabel($labels,"y");
}

sub SetXAxisSpacing{
  my $self = shift;
  my $spacing = shift;
  $self->{xAxisSpacing} = $spacing;
}#sub SetXAxisSpacing


sub SetYAxisSpacing{
  my $self = shift;
  my $spacing = shift;
  $self->{yAxisSpacing} = $spacing;
}#sub SetYAxisSpacing


sub ScatterGraph{
  my $self = shift;
  my $dataset = shift;
  my $shape = shift;
  my $color = shift;
  $self->{current_dataset} = $dataset;
  $self->{legend}{$dataset}{'ScatterGraph'} = {"color" => $color, 'shape' => $shape};

  reset($self->{data_set}[$dataset]{"x"});

  for (my $i=0; $i < $self->{num_points}[$dataset]; $i++) {
    my $x = $self->{data_set}[$dataset]{"x"}[$i];
    my $y = $self->{data_set}[$dataset]{"y"}[$i];
    $self->GraphBrush($x,$y,$shape,$color);
  }
}#sub ScatterGraph

sub VBarGraph{
  my $self = shift;
  my $dataset = shift;
  my $color = shift;
  $self->{current_dataset} = $dataset;
  $self->{legend}{$dataset}{'VBarGraph'} = {"color" => $color};

  for (my $i = 0; $i < $self->{num_points}[$dataset]; $i++) {
    $self->GraphVBar($self->{data_set}[$dataset]{"x"}[$i], $self->{data_set}[$dataset]{"y"}[$i], $color);
  }
}#sub BarGraph



sub PieChart{
  my $self = shift;
  my $pieData = shift;
  my $name = $pieData->{name};
  my $data = $pieData->{data};
  my $radMod = $pieData->{radMod};
  my $title = $pieData->{title};
  if (!defined($title)){
    $title ="";
  }

  #my $maxLength = length($title);
  my $maxLength = $self->GetTextSize($title,0);
  $maxLength = $maxLength->{width};
  foreach my $thisname (@$name) {
    my $tempWidth = $self->GetTextSize($thisname,0);
    $maxLength = $self->max($maxLength,$tempWidth->{width});
  }
  reset ($name);

  my $pieProps        = $self->InitPieChart();
  my $xAngle          = $pieProps->{"xAngle"};
  my $yAngle          = $pieProps->{"yAngle"};
  my $zAngle          = $pieProps->{"zAngle"};
  my $dMod            = $pieProps->{"dMod"};
  my $defaultRadMod   = $pieProps->{"radMod"};
  my $startHeightMod  = $pieProps->{"startHeightMod"};
  my $edgeColor       = $pieProps->{"edgeColor"};
  my $maxDepth        = $pieProps->{"maxDepth"};

  my $titlePad        = 15;
  my $legendBoxHeight = 15;
  my $legendBoxSpace  = 8;
  my $legendHeightMod = $legendBoxHeight + $legendBoxSpace + 1;
  my $maxMod = $self->max($defaultRadMod,($self->ArrayMax($radMod)));
  $self->{image_width} = $self->max($self->{image_width},$maxMod+(0.75 * $self->{image_width})); # + ($maxLength * 1));
  my $radius = ($self->{image_width} - 10) * .2;
  #my $radius = ($self->{image_width} - 10) * .3;

  $self->{image_height} = $self->max(2 * ($radius + $maxMod/2) + $self->{ypad},scalar(@$data) * $legendHeightMod + $titlePad);

  $self->InitGraph($self->{image_width},$self->{image_height});

  my $color          = $self->GeneratePieChartColors(scalar(@$data));

  #$radius = ($self->{image_width} - 10) * .3;
  $radius      = $self->min(($self->{image_width} - 10-(.75*$maxMod)) * .2,($self->{image_height} - 40-(.75*$maxMod)) * .5);
  my $absCenterX  = int(($radius + ($radius / 10) + (.75*$maxMod)) + 20 +.5);
  my $absCenterY  = int($radius + 10 + .75*$maxMod +.5);
  my $legend_left = 2 * $absCenterX;
  my $legend_top  = 10;
  my $degreeSteps = 6;

  if (defined($title)) {
    $self->DrawText($self->{font},$legend_left,$legend_top,$title,"black",0);
    $self->DrawLine($legend_left - 2,$legend_top + $titlePad,$legend_left + (length($title) * 5.2),$legend_top + $titlePad,"black");
    $legend_top =  $legend_top + 25;
  }

  #arsort($data);

  my $total = 0;
  for (my $i = 0;  $i < scalar(@$data); $i++){
    $total = $total + @$data->[$i];
  }

  if (!defined(@$data)) {
    $color->[0] = "white";
    $data->[0]  = 0;
    $total    = 0;
  }

  my %piePolys;
  my %side1Polys;
  my %side2Polys;
  my @edgePolys;
  my %polyOrder;
  my @pieColors;
  my $end_angle  = 360;
  my $colorCount = 0;

  reset($data);

  for (my $pieceNumber = 0;  $pieceNumber < scalar(@$data); $pieceNumber++){
    my $value = $data->[$pieceNumber];
    my $start_angle = $end_angle;

    if ($total) {
      $end_angle = $start_angle - (($value / $total) * 360);
    } else {
      $end_angle = 0;
    }

    if ($end_angle < 0) {
      $end_angle = 0;
    }
    my $pieceRadMod;
    if (defined(@$radMod->[$pieceNumber])){
      $pieceRadMod = $radMod->[$pieceNumber];
    }
    else{
      $pieceRadMod = $defaultRadMod;
    }
    my $bisector   = ($start_angle + $end_angle) / 2;
    my $centerx    = $absCenterX + $pieceRadMod * cos($self->deg2rad($bisector));
    my $centery    = $absCenterY + $pieceRadMod * sin($self->deg2rad($bisector));
    my $startDepth = $pieceNumber * $startHeightMod;
    my $xPos;
    my $yPos;
    my $topPoint;
    my $bottomPoint;

    @{$piePolys{$pieceNumber}{"top"}} = ();
    @{$piePolys{$pieceNumber}{"bottom"}} = ();
    for (my $angle = $end_angle; $angle < ($start_angle - $self->min($degreeSteps/2,abs($start_angle - $end_angle) / 2)); $angle = $angle + $degreeSteps){
      $xPos = $radius * cos($self->deg2rad($angle)) + $centerx;
      $yPos = $centery + $radius * sin($self->deg2rad($angle));

      $topPoint    = $self->GetPerspectiveXY($absCenterX,$absCenterY,$xPos,$yPos,0,$xAngle,$yAngle,$zAngle);
      $bottomPoint = $self->GetPerspectiveXY($absCenterX,$absCenterY,$xPos,$yPos,$dMod * $maxDepth,$xAngle,$yAngle,$zAngle);
      push(@{$piePolys{$pieceNumber}{"top"}}, $topPoint);
      push(@{$piePolys{$pieceNumber}{"bottom"}}, $bottomPoint);

      if ($angle == $end_angle) {
        push(@{$side1Polys{$pieceNumber}},$topPoint);
        push(@{$side1Polys{$pieceNumber}},$bottomPoint);
      }
    }

    $xPos = $radius * cos($self->deg2rad($start_angle)) + $centerx;
    $yPos = $centery + $radius * sin($self->deg2rad($start_angle));

    $topPoint    = $self->GetPerspectiveXY($absCenterX,$absCenterY,$xPos,$yPos,0,$xAngle,$yAngle,$zAngle);
    $bottomPoint = $self->GetPerspectiveXY($absCenterX,$absCenterY,$xPos,$yPos,$dMod * $maxDepth,$xAngle,$yAngle,$zAngle);

    push(@{$piePolys{$pieceNumber}{"top"}},$topPoint);
    push(@{$piePolys{$pieceNumber}{"bottom"}},$bottomPoint);

    @{$edgePolys[$pieceNumber]} = @{$piePolys{$pieceNumber}{"top"}};
    push(@{$edgePolys[$pieceNumber]} ,reverse @{$piePolys{$pieceNumber}{"bottom"}});

    push(@{$side2Polys{$pieceNumber}},$topPoint);
    push(@{$side2Polys{$pieceNumber}},$bottomPoint);

    if (((scalar(@$data)) > 1) && ($value != $total)) {
      $topPoint    = $self->GetPerspectiveXY($absCenterX,$absCenterY,$centerx,$centery,0,$xAngle,$yAngle,$zAngle);
      $bottomPoint = $self->GetPerspectiveXY($absCenterX,$absCenterY,$centerx,$centery,$dMod * $maxDepth,$xAngle,$yAngle,$zAngle);

      push(@{$piePolys{$pieceNumber}{"top"}},$topPoint);
      push(@{$piePolys{$pieceNumber}{"bottom"}},$bottomPoint);

      push(@{$side1Polys{$pieceNumber}},$bottomPoint);
      push(@{$side1Polys{$pieceNumber}},$topPoint);

      push(@{$side2Polys{$pieceNumber}},$bottomPoint);
      push(@{$side2Polys{$pieceNumber}},$topPoint);
    }

    my $orderX = $absCenterX + $radius * cos($self->deg2rad($bisector));
    my $orderY = $absCenterY + $radius * sin($self->deg2rad($bisector));
    my $depth;
    my $order  = $self->GetPerspectiveXY($absCenterX,$absCenterY,$orderX,$orderY,$dMod * $depth,$xAngle,$yAngle,$zAngle);
    $polyOrder{$pieceNumber} = $order->{"y"};

    if (defined($total)) {
      $self->DrawFilledRectangle($legend_left,$legend_top,$legendBoxHeight,$legendBoxHeight,$color->[$colorCount]);
      $self->DrawRectangle($legend_left,$legend_top,$legendBoxHeight,$legendBoxHeight,"black");

      my $totalPercentage = ($total ? (int(($value / $total * 1000)+.5) / 10) : "0");
      my $strLegend = " - " . @$name->[$pieceNumber] . ": " . @$data->[$pieceNumber] . " (" . $totalPercentage . "%)";
      $self->DrawText($self->{font},$legend_left + 20, $legend_top, $strLegend,"black",0);
      $legend_top = $legend_top + $legendBoxHeight + $legendBoxSpace;
      $pieColors[$pieceNumber] = $colorCount;
      $colorCount++;
    }

  }

  foreach my $pieceNumber (sort keys %polyOrder){
    $colorCount = $pieColors[$pieceNumber];
    my $startDepth = $pieceNumber * $startHeightMod;
    my $lastVert   = scalar(@{$piePolys{$pieceNumber}{"bottom"}}) - 1;

    $self->DrawPolygon($piePolys{$pieceNumber}{"bottom"}, $edgeColor);

    $self->DrawLine($piePolys{$pieceNumber}{top}[$lastVert]{x},$piePolys{$pieceNumber}{top}[$lastVert]{y},$piePolys{$pieceNumber}{bottom}[$lastVert]{x}, $piePolys{$pieceNumber}{bottom}[$lastVert]{y},$edgeColor);

    $self->DrawLine($piePolys{$pieceNumber}{"top"}[$lastVert - 1]{"x"},$piePolys{$pieceNumber}{"top"}[$lastVert - 1]{"y"},$piePolys{$pieceNumber}{"bottom"}[$lastVert - 1]{"x"},$piePolys{$pieceNumber}{"bottom"}[$lastVert - 1]{"y"},$edgeColor);

    $self->DrawLine($piePolys{$pieceNumber}{"top"}[0]{"x"},$piePolys{$pieceNumber}{"top"}[0]{"y"},$piePolys{$pieceNumber}{"bottom"}[0]{"x"},$piePolys{$pieceNumber}{"bottom"}[0]{"y"},$edgeColor);

    $self->DrawFilledPolygon($piePolys{$pieceNumber}{"bottom"}, "translucent-" . $color->[$colorCount]);
    $self->DrawFilledPolygon($edgePolys[$pieceNumber], $color->[$colorCount]);
    $self->DrawFilledPolygon($side1Polys{$pieceNumber}, "translucent-" . $color->[$colorCount]);
    $self->DrawFilledPolygon($side2Polys{$pieceNumber}, "translucent-" . $color->[$colorCount]);
    $self->DrawFilledPolygon($piePolys{$pieceNumber}{"top"}, $color->[$colorCount]);

    $self->DrawPolygon($piePolys{$pieceNumber}{"top"}, $edgeColor);
  }
} #sub PieChart


sub GeneratePieChartColors{
  my $self = shift;
  my $numData = shift;
  my $alternate = shift;

  if (!defined($alternate)){
    $alternate = 1;
  }

  my $mult;
  if ($alternate) {
    $mult = 2;
  } else {
    $mult = 1;
  }

  my $interval   = floor((768 * $mult) / $self->max($numData,1));
  my @colors;
  my $colorCount = 0;

  for (my $i = 1; $i <= 768; $i = $i+$interval) {
    my $colorMod = floor($i / 256);
    my ($r, $g, $b);

    if ($colorMod == 0){
      $r = 256 - $i;
      $g = $i - 1;
      $b = 0;
    }
    
    if ($colorMod == 1){
      $r = 0;
      $g = 512 - $i;
      $b = $i - 256;
    }
  
    if ($colorMod == 2){
      $r = $i - 512;
      $g = 0;
      $b = 768 - $i;
    }

    if ($r > 255){
      $r = 255;
    }
    if ($r < 0){
      $r = 0;
    }

    if ($g > 255){
      $g = 255;
    }
    if ($g < 0){
      $g = 0;
    }

    if ($b > 255){
      $b = 255;
    }
    if ($b < 0){
      $b = 0;
    }

    my $colorName = "pie" . $colorCount;

    $self->CreateColor($colorName,$r,$g,$b,155);
    $colors[$colorCount] = $colorName;
    $colorCount++;

    if ($alternate) {
      $colorName = "pie" . $colorCount;

      $self->CreateColor($colorName,255 - $r,255 - $g,255 - $b,155);
      $colors[$colorCount] = $colorName;
      $colorCount++;
    }

  }

  return \@colors;
} #sub GeneratePieChartColors



sub GetPerspectiveXY{
  my $self = shift;
  my $xCenter = shift;
  my $yCenter = shift;
  my $xIn = shift;
  my $yIn = shift;
  my $zIn = shift;
  my $xAngle = shift;
  my $yAngle = shift;
  my $zAngle = shift;

  my $xPos = $xIn - $xCenter;
  my $yPos = $yIn - $yCenter;
  my $zPos = $zIn;
  
  my @trans;
  my @pos;

  if ($xAngle != 0) {
    $trans[0][0] = 1;
    $trans[0][1] = 0;
    $trans[0][2] = 0;
    $trans[1][0] = 0;
    $trans[1][1] = cos($self->deg2rad($xAngle));
    $trans[1][2] = -sin($self->deg2rad($xAngle));
    $trans[2][0] = 0;
    $trans[2][1] = sin($self->deg2rad($xAngle));
    $trans[2][2] = cos($self->deg2rad($xAngle));

    $pos[0][0] = $xPos;
    $pos[1][0] = $yPos;
    $pos[2][0] = $zPos;

    ($xPos,$yPos,$zPos) = $self->CrossProduct(\@trans,\@pos);
  }

  if ($yAngle != 0) {
    $trans[0][0] = cos($self->deg2rad($yAngle));
    $trans[0][1] = 0;
    $trans[0][2] = sin($self->deg2rad($yAngle));
    $trans[1][0] = 0;
    $trans[1][1] = 1;
    $trans[1][2] = 0;
    $trans[2][0] = -sin($self->deg2rad($yAngle));
    $trans[2][1] = 0;
    $trans[2][2] = cos($self->deg2rad($yAngle));

    $pos[0][0] = $xPos;
    $pos[1][0] = $yPos;
    $pos[2][0] = $zPos;

    ($xPos,$yPos,$zPos) = $self->CrossProduct(\@trans,\@pos);
  }

  if ($zAngle != 0) {
    $trans[0][0] = cos($self->deg2rad($zAngle));
    $trans[0][1] = -sin($self->deg2rad($zAngle));
    $trans[0][2] = 0;
    $trans[1][0] = sin($self->deg2rad($zAngle));
    $trans[1][1] = cos($self->deg2rad($zAngle));
    $trans[1][2] = 0;
    $trans[2][0] = 0;
    $trans[2][1] = 0;
    $trans[2][2] = 1;

    $pos[0][0] = $xPos;
    $pos[1][0] = $yPos;
    $pos[2][0] = $zPos;

    ($xPos,$yPos,$zPos) = $self->CrossProduct(\@trans,\@pos);
  }

  my $xOut = int($xPos + $xCenter+.5);
  my $yOut = int($yPos + $yCenter+.5);

  return {"x" => $xOut, "y" => $yOut};
}# sub GetPerspectiveXY

sub GetImageID{
  my $self = shift;
  return $self->{im};
} #sub GetImageID


sub CrossProduct{
  my $self = shift;
  my $matrix1 = shift;
  my $matrix2 = shift;
  my @result;

  if ((scalar(@{$matrix1->[0]})) == (scalar(@$matrix2))) {
    my $i = -1;

    for (my $i=0; $i<(scalar(@$matrix1)); $i++){
      my $cols = $matrix1->[$i];
      my $j = -1;
      my $this_result = 0;
   
      for (my $j=0; $j<(scalar(@$cols)); $j++){
        $this_result = $this_result + $cols->[$j] * $matrix2->[$j][0];
      }

      $result[$i] = $this_result;
    }

  }
  else {
    #$result = array();
  }

  return @result;
} #sub CrossProduct




sub NoData{
  my $self = shift;
  $self->InitGraph(80,20);
  $self->DrawText($self->{font},20,0, "No Data","black",0);
}



sub AddChart{
  my $self = shift;
  my $type = shift;
  my $data1 = shift;
  if (!defined($data1)){
    $data1 = "";
  }
  if (!defined($self->{chartCount})) {
    $self->{chartCount} = 0;
  } else {
    $self->{chartCount}++;
  }

  my $totalDataSets = scalar(@_) - 1;
  if ($data1) {
    for (my $i = 1; $i <= $totalDataSets; ++$i) {
     push(@{$self->{chartData}[$self->{chartCount}]}, $_[$i]);
    }
  }
  return ($self->{chartCount});
}



sub AddChartData($chartID,$data) {
  my $self = shift;
  my $chartID = shift;
  my $data = shift;
  push(@{$self->{chartData}[$chartID]}, $data);
} # sub AddChartData



sub VBarChart{
  my $self = shift;
  my $chartID = shift;
  my $dataset;
  $self->{current_dataset} = $dataset;
  my $totalDataSets = scalar(@$self->{chartData}[$chartID]);

  if ($totalDataSets) {
    my $colors = $self->GeneratePieChartColors($totalDataSets,0);

    my $offSet = 6;
    my $count  = ceil(($totalDataSets / 2) - $totalDataSets);

    my %tempHash = %$self->{chartData}[$chartID];
    while (my ($foo,$dataset) = each %tempHash) {
      $self->{legend}{$dataset}{"VBarGraph"} = {"color" => @$colors[$foo]};

      my $xOffset = $offSet * $count;

      for (my $i = 0; $i < $self->{num_points}[$dataset]; $i++) {
        $self->GraphVBar($self->{data_set}[$dataset]{"x"}[$i], $self->{data_set}[$dataset]{"y"}[$i], @$colors[$foo], $xOffset);
      }

      $count++;
    }

    return 1;

  } else {
    return 0;
  }
} #sub VBarChart

sub ArrayMin{
  my $self = shift;
  my $x = shift;
  my $i = 0;
  my $tmpMin = $x->[$i];
  for (my $i=1; $i<scalar(@$x); $i++){
    if ($x->[$i] < $tmpMin){
      $tmpMin = $x->[$i];
    }
  }
  return $tmpMin;
}



sub ArrayMax{
  my $self = shift;
  my $x = shift;
  my $i = 0;
  my $tmpMax = $x->[$i];
  for (my $i=1; $i<scalar(@$x); $i++){
    if ($x->[$i] > $tmpMax){
      $tmpMax = $x->[$i];
    }
  }
  return $tmpMax;
}


sub min{
  my $self = shift;
  my $x = shift;
  my $y = shift;
  if ($x>$y){
    return $y;
  }
  else{
    return $x;
  }
}

sub max{
  my $self = shift;
  my $x = shift;
  my $y = shift;

  if ($x>$y){
    return $x;
  }
  else{
    return $y;
  }
}

sub deg2rad{
  my $self = shift;
  my $degrees = shift;
  my $pi = 3.14159210535152623346475240375062163750446240333543375062;
  my $result = ($degrees * 2 * $pi)/360;
  return $result;
}

sub HighlightRegion{
  my $self= shift;
  my $orientation = shift;
  my $regionMin = shift;
  my $regionMax = shift;
  my $regionColor = shift;
  my $regionMessage = shift;
  my $xStart;
  my $xEnd;
  my $yStart;
  my $yEnd;
  my $width;
  my $height;

  my $strSize = $self->GetTextSize($regionMessage,0);

  if ($orientation eq "horizontal"){
    ($xStart, $yStart) = $self->translate($self->{xmin},$regionMax);
    ($xEnd, $yEnd) = $self->translate($self->{xmax},$regionMin);
    $self->DrawText($self->{font},$self->{xpad}+$width - ($strSize->{"width"}/2),$yStart+($strSize->{"height"} / 2),$regionMessage,"black",0);
  }
  else{
    if ($orientation eq "vertical"){
      ($xStart, $yStart) = $self->translate($regionMin,$self->{ymax});
      ($xEnd, $yEnd) = $self->translate($regionMax, $self->{ymin});
      $self->DrawText($self->{font},$regionMin+($width - ($strSize->{"width"}/2)),$yStart+($strSize->{"height"} / 2),$regionMessage,"black",0);
    }
    else{
      die("Invalid Orientation: $orientation");
    }
  }
  $width = $xEnd - $xStart;
  $height = $yEnd - $yStart;

print STDERR ("From:($self->{xmin},$regionMax) -> ($xStart, $yStart)\n To:($self->{xmax},$regionMin) -> ($xEnd, $yEnd)\n Width: $width, Height: $height\n");
  
  $self->DrawFilledRectangle($xStart,$yStart,$width,$height,$regionColor);
}


1;

__END__

=pod

=head1 NAME

Gadabout

=head1 SYNOPSIS

Gadabout is a reimplementation and improvement on the software called
Vagrant which was written for PHP.

=head1 EXAMPLES

=head2 Line Graphs

  my $graph = new Gadabout;
  $graph->InitGraph(500,500);
  $graph->AddFontPath('/usr/local/share/fonts/ttf'));
  $graph->SetFont('arial/8');

  $graph->SetTitle('Example Graph');
  $graph->SetSubTitle('subtitle goes here');
  $graph->SetxTitle('x axis');
  $graph->SetyTitle('Trig Functions');
  $graph->SetAxis2Title('Polynomial');
  $graph->{use_axis2} = 1;

  my $data1 = $graph->AddData(\@x,\@y1,"log((x^(x/10))+1)*sin(x/15)");
  my $data3 = $graph->AddData(\@x3,\@y3,"30cos(x/10)");
  my $data2 = $graph->AddData(\@x,\@y2,
                "((((x-50)/10)^3)-(3*(((x-50)/10)^2))+(.4x))");
  $graph->DrawGrid('gray');
  $graph->LineGraph($data1,"green");
  $graph->ScatterGraph($data2,'circle','translucent-blue');
  $graph->VBarGraph($data3,"translucent-red");

  $graph->DrawAxis();
  $graph->ShowGraph('out.png');

=head2 Pie Charts

  my %pieData;
  my @names = ('Cat A', 'Cat B', 'Cat C', Cat D');
  my @data =  (  12345,   23413,    2314,   8000);
  my @radmods = (   20,       0,       0,     40);
  $pieData{name} = \@name;
  $pieData{data} = \@data;
  $pieData{radMod} = \@radmods;
  $pieData{title} = 'Sample Graph';

  my $graph = new Gadabout;
  $graph->InitGraph(500,200);
  $graph->AddFontPath('/usr/local/share/fonts/ttf'));
  $graph->SetFont('arial/8');

  $graph->PieChart(\%pieData);
  $graph->ShowGraph('output.png');

=head1 COPYRIGHT

OmniTI Computer Consulting, Inc.  Copyright (c) 2003

=head1 AUTHOR

Ben Martin <bmartin@omniti.com>

Theo Schlossnagle <jesus@omniti.com>

OmniTI Computer Consulting, Inc.

=cut

