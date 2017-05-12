package LaTeX::PGF::Diagram2D;

use 5.000000;
use strict;
use warnings;
use Carp;
use POSIX;

our @ISA = qw();

require LaTeX::PGF::Diagram2D::Axis;
require LaTeX::PGF::Diagram2D::Plot;
require LaTeX::PGF::Diagram2D::NumberPrinter;
require LaTeX::PGF::Diagram2D::Label;
require LaTeX::PGF::Diagram2D::Polyline;


our $VERSION = '1.02';


# Preloaded methods go here.


sub new
{
  my $self = undef;
  if($#_ < 2) {
    croak "Usage: LaTeX::PGF::Diagram2D->new(width,height)";
  } else {
    my $class = shift;
    my $width = shift;
    my $height = shift;
    my @pl;
    my @co;
    my $ab = LaTeX::PGF::Diagram2D::Axis->new(); $ab->{'n'} = 'b';
    my $al = LaTeX::PGF::Diagram2D::Axis->new(); $al->{'n'} = 'l';
    my $ar = LaTeX::PGF::Diagram2D::Axis->new(); $ar->{'n'} = 'r';
    my $at = LaTeX::PGF::Diagram2D::Axis->new(); $at->{'n'} = 't';
    $ab->{'used'} = 1;
    $al->{'used'} = 1;
    $self = {
      'type' => 0,		# Type: 0=grid, 1=quantitative, 2=qualitative
      'units' => 0,		# Units: 0=cm, 1=inches, 2=bp
      'w' => $width,		# Graph width
      'h' => $height,		# Graph height
      'p' => \@pl,		# Plots in the diagram
      'np' => 0,		# Number of plots in array above
      'b' => $ab,		# Bottom x axis
      'l' => $al,		# Left y axis
      'r' => $ar,		# Right y axis
      't' => $at,		# Top x axis
      'texpre' => undef,	# Additional LaTeX preamble lines
      'fs' => 10.0,		# Font size
      'decsgn' => ',',		# Decimal sign
      'contents' => \@co,	# Additional contents
      'nco' => 0,		# Number of elements in array above
      'x0' => 0.0,
      'x1' => 0.0,
      'x2' => 0.0,
      'x3' => 0.0,
      'x4' => 0.0,
      'x5' => 0.0,
      'x6' => 0.0,
      'x7' => 0.0,
      'y0' => 0.0,
      'y1' => 0.0,
      'y2' => 0.0,
      'y3' => 0.0,
      'y4' => 0.0,
      'y5' => 0.0,
      'y6' => 0.0,
      'y7' => 0.0,
      'x0bp' => 0.0,
      'x1bp' => 0.0,
      'x2bp' => 0.0,
      'x3bp' => 0.0,
      'x4bp' => 0.0,
      'x5bp' => 0.0,
      'x6bp' => 0.0,
      'x7bp' => 0.0,
      'y0bp' => 0.0,
      'y1bp' => 0.0,
      'y2bp' => 0.0,
      'y3bp' => 0.0,
      'y4bp' => 0.0,
      'y5bp' => 0.0,
      'y6bp' => 0.0,
      'y7bp' => 0.0,
      'f1' => undef,		# Output file handle
      'fn1' => undef,		# LaTeX output file name
      'ftf' => 0,		# Flag: Full LaTeX file
      'debug' => 0,		# Debugging
      'pgf_c' => undef,		# Current color
      'pgf_w' => undef,		# Current linewidth
    };
    bless($self, $class);
    $ab->set_linear(0.0, $width)->set_grid_step(1.0)->set_tic_step(1.0);
    $al->set_linear(0.0, $height)->set_grid_step(1.0)->set_tic_step(1.0);
    $ar->set_linear(0.0, $height);
    $at->set_linear(0.0, $width);
    $ab->{'dg'} = $self; $al->{'dg'} = $self;
    $ar->{'dg'} = $self; $at->{'dg'} = $self;
  }
  return $self;
}



sub rd
{
  my $back = undef;
  if($#_ < 2) {
    croak "Usage: \$diagram->rd(value,digits)";
  } else {
    my $self = shift;
    $back = shift;
    my $digits = shift;
    my $i = 0;
    for($i = 0; $i < $digits; $i++) {
      $back = 10.0 * $back;
    }
    $back = floor($back + 0.5);
    for($i = 0; $i < $digits; $i++) {
      $back = $back / 10.0;
    }
  }
  return $back;
}



sub write_tex_coord
{
  my $self = shift;
  my $value = shift;
  my $fh = $self->{'f1'};
  $value = $self->rd($value, 5);
  my $t = sprintf("%g", $value);
  # ##### Exponentialschreibweise deaktivieren
  print $fh $t;
}



sub write_point
{
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $fh = $self->{'f1'};
  print $fh "\\pgfpoint{";
  $self->write_tex_coord($x);
  print $fh "bp}{";
  $self->write_tex_coord($y);
  print $fh "bp}";
}



sub prepare_for_output
{
  my $back = undef;
  if($#_ < 0) {
    croak "Usage: \$diagram->prepare_for_output()";
  } else {
    my $self = shift;
    $back = 1;
    $self->{'b'}->correct_if_necessary($self, 0, $self->{'debug'});
    $self->{'l'}->correct_if_necessary($self, 1, $self->{'debug'});
    $self->{'r'}->correct_if_necessary($self, 1, $self->{'debug'});
    $self->{'t'}->correct_if_necessary($self, 0, $self->{'debug'});
    $self->{'x0'} = 0.0;
    $self->{'x3'} = $self->{'l'}->{'bo'};
    $self->{'x2'} = $self->{'x3'}; $self->{'x1'} = $self->{'x3'};
    if($self->{'l'}->{'to'} > 0.0) {
      $self->{'x2'} = $self->{'x3'} - $self->{'l'}->{'to'};
    }
    if($self->{'l'}->{'lo'} > 0.0) {
      $self->{'x1'} = $self->{'x3'} - $self->{'l'}->{'lo'};
    }
    $self->{'x4'} = $self->{'x3'} + $self->{'w'};
    $self->{'x5'} = $self->{'x4'}; $self->{'x6'} = $self->{'x4'};
    if($self->{'r'}->{'to'} > 0.0) {
      $self->{'x5'} = $self->{'x4'} + $self->{'r'}->{'to'};
    }
    if($self->{'r'}->{'lo'} > 0.0) {
      $self->{'x6'} = $self->{'x4'} + $self->{'r'}->{'lo'};
    }
    $self->{'x7'} = $self->{'x4'} + $self->{'r'}->{'bo'};
    $self->{'y0'} = 0.0;
    $self->{'y3'} = $self->{'b'}->{'bo'};
    $self->{'y1'} = $self->{'y3'}; $self->{'y2'} = $self->{'y3'};
    if($self->{'b'}->{'to'} > 0.0) {
      $self->{'y2'} = $self->{'y3'} - $self->{'b'}->{'to'};
      if($self->{'units'} == 1) {
        $self->{'y2'} = $self->{'y2'} - ($self->{'fs'} / 72.27);
      } else {
        if($self->{'units'} == 2) {
	  $self->{'y2'} = $self->{'y2'} - ((72.0 * $self->{'fs'}) / 72.27);
	} else {
	  $self->{'y2'} = $self->{'y2'} - ((2.54 * $self->{'fs'}) / 72.27);
	}
      }
    }
    if($self->{'b'}->{'lo'} > 0.0) {
      $self->{'y1'} = $self->{'y3'} - $self->{'b'}->{'lo'};
    }
    $self->{'y4'} = $self->{'y3'} + $self->{'h'};
    $self->{'y5'} = $self->{'y4'}; $self->{'y6'} = $self->{'y4'};
    $self->{'y7'} = $self->{'y4'} + $self->{'t'}->{'bo'};
    if($self->{'t'}->{'to'} > 0.0) {
      $self->{'y5'} = $self->{'y4'} + $self->{'t'}->{'to'};
    }
    if($self->{'t'}->{'lo'} > 0.0) {
      $self->{'y6'} = $self->{'y4'} + $self->{'t'}->{'lo'};
    }
    my $scf;
    if($self->{'units'} == 1) {
      $scf = 72.0;
    } else {
      if($self->{'units'} == 2) {
        $scf = 1.0;
      } else {
        $scf = 72.0 / 2.54;
      }
    }
    $self->{'x0bp'} = $self->rd($scf * $self->{'x0'}, 5);
    $self->{'x1bp'} = $self->rd($scf * $self->{'x1'}, 5);
    $self->{'x2bp'} = $self->rd($scf * $self->{'x2'}, 5);
    $self->{'x3bp'} = $self->rd($scf * $self->{'x3'}, 5);
    $self->{'x4bp'} = $self->rd($scf * $self->{'x4'}, 5);
    $self->{'x5bp'} = $self->rd($scf * $self->{'x5'}, 5);
    $self->{'x6bp'} = $self->rd($scf * $self->{'x6'}, 5);
    $self->{'x7bp'} = $self->rd($scf * $self->{'x7'}, 5);
    $self->{'y0bp'} = $self->rd($scf * $self->{'y0'}, 5);
    $self->{'y1bp'} = $self->rd($scf * $self->{'y1'}, 5);
    $self->{'y2bp'} = $self->rd($scf * $self->{'y2'}, 5);
    $self->{'y3bp'} = $self->rd($scf * $self->{'y3'}, 5);
    $self->{'y4bp'} = $self->rd($scf * $self->{'y4'}, 5);
    $self->{'y5bp'} = $self->rd($scf * $self->{'y5'}, 5);
    $self->{'y6bp'} = $self->rd($scf * $self->{'y6'}, 5);
    $self->{'y7bp'} = $self->rd($scf * $self->{'y7'}, 5);
    # ##### Check and prepare
    if($self->{'debug'}) {
      print "DEBUG   x0   = " . $self->{'x0'} . "\n";
      print "DEBUG   x1   = " . $self->{'x1'} . "\n";
      print "DEBUG   x2   = " . $self->{'x2'} . "\n";
      print "DEBUG   x3   = " . $self->{'x3'} . "\n";
      print "DEBUG   x4   = " . $self->{'x4'} . "\n";
      print "DEBUG   x5   = " . $self->{'x5'} . "\n";
      print "DEBUG   x6   = " . $self->{'x6'} . "\n";
      print "DEBUG   x7   = " . $self->{'x7'} . "\n";
      print "DEBUG   y0   = " . $self->{'y0'} . "\n";
      print "DEBUG   y1   = " . $self->{'y1'} . "\n";
      print "DEBUG   y2   = " . $self->{'y2'} . "\n";
      print "DEBUG   y3   = " . $self->{'y3'} . "\n";
      print "DEBUG   y4   = " . $self->{'y4'} . "\n";
      print "DEBUG   y5   = " . $self->{'y5'} . "\n";
      print "DEBUG   y6   = " . $self->{'y6'} . "\n";
      print "DEBUG   y7   = " . $self->{'y7'} . "\n";
      print "DEBUG   x0bp = " . $self->{'x0bp'} . "\n";
      print "DEBUG   x1bp = " . $self->{'x1bp'} . "\n";
      print "DEBUG   x2bp = " . $self->{'x2bp'} . "\n";
      print "DEBUG   x3bp = " . $self->{'x3bp'} . "\n";
      print "DEBUG   x4bp = " . $self->{'x4bp'} . "\n";
      print "DEBUG   x5bp = " . $self->{'x5bp'} . "\n";
      print "DEBUG   x6bp = " . $self->{'x6bp'} . "\n";
      print "DEBUG   x7bp = " . $self->{'x7bp'} . "\n";
      print "DEBUG   y0bp = " . $self->{'y0bp'} . "\n";
      print "DEBUG   y1bp = " . $self->{'y1bp'} . "\n";
      print "DEBUG   y2bp = " . $self->{'y2bp'} . "\n";
      print "DEBUG   y3bp = " . $self->{'y3bp'} . "\n";
      print "DEBUG   y4bp = " . $self->{'y4bp'} . "\n";
      print "DEBUG   y5bp = " . $self->{'y5bp'} . "\n";
      print "DEBUG   y6bp = " . $self->{'y6bp'} . "\n";
      print "DEBUG   y7bp = " . $self->{'y7bp'} . "\n";
    }
  }
  return $back;
}



sub write_rect
{
  my $self = shift;
  my $x0 = shift; my $y0 = shift; my $x1 = shift; my $y1 = shift;
  my $fh = $self->{'f1'};
  print $fh "\\pgfpathmoveto{";
  $self->write_point($x0, $y0);
  print $fh "}\n\\pgfpathlineto{";
  $self->write_point($x1, $y0);
  print $fh "}\n\\pgfpathlineto{";
  $self->write_point($x1, $y1);
  print $fh "}\n\\pgfpathlineto{";
  $self->write_point($x0, $y1);
  print $fh "}\n\\pgfpathclose\n";
}




sub write_clip
{
  my $self = shift;
  my $x0 = shift; my $y0 = shift; my $x1 = shift; my $y1 = shift;
  my $fh = $self->{'f1'};
  $self->write_rect($x0, $y0, $x1, $y1);
  print $fh "\\pgfusepath{clip}\n";
}


sub setlinewidth_mm
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$diagram->setlinewidth_mm(value)";
  } else {
    $self = shift; my $value = shift;
    my $fh = $self->{'f1'};
    $value = $value / 10.0; $value = $self->rd($value, 5);
    my $mustprint = 1;
    if(defined($self->{'pgf_w'})) {
      if($self->{'pgf_w'} eq "$value") {
        $mustprint = 0;
      }
    }
    if($mustprint) {
      print $fh "\\pgfsetlinewidth{" . $value . "cm}\n";
      $self->{'pgf_w'} = $value;
    }
  }
  return $self;
}



sub set_color
{
  my $self = shift;
  my $color = shift;
  my $fh = $self->{'f1'};
  my $mustprint = 1;
  if(defined($self->{'pgf_c'})) {
    if($self->{'pgf_c'} eq "$color") {
      $mustprint = 0;
    }
  }
  if($mustprint) {
    print $fh "\\pgfsetcolor{$color}\n";
    $self->{'pgf_c'} = $color;
  }
  return $self;
}



sub begin_pgfscope
{
  my $self = shift;
  my $fh = $self->{'f1'};
  print $fh "\\begin{pgfscope}\n";
  return $self;
}



sub end_pgfscope
{
  my $self = shift;
  my $fh = $self->{'f1'};
  print $fh "\\end{pgfscope}\n";
  $self->{'pgf_c'} = undef;
  $self->{'pgf_w'} = undef;
  return $self;
}



sub draw_axis_grid
{
  my $self = shift;
  my $ax = shift;
  my $xyflag = shift;
  my $fh = $self->{'f1'};
  my $xs = $ax->{'min'}; my $xe = $ax->{'max'};
  my $st = $ax->{'gs'};
  if($st > 0.0) {
    if($ax->{'min'} > $ax->{'max'}) {
      $xs = $ax->{'max'}; $xe = $ax->{'min'};
    }
    my $x = $xs; my $num = 0;
    my $mustprint = 1; my $co = 0.0;
    if($self->{'debug'}) {
      print "DEBUG (1) xs=$xs xe=$xe st=$st x=$x\n";
    }
    while(($x < $xe) && ($num < 1000)) {
      if($ax->{'t'}) {
        if($st > 1.0) {
	  $x = $x * $st;
	} else {
	  $x = $x / $st;
	}
      } else {
        $x = $x + $st;
      }
      if($self->{'debug'}) {
        print "DEBUG (2) xs=$xs xe=$xe st=$st x=$x\n";
      }
      $mustprint = 1;
      if($ax->{'t'}) {
	if($st > 1.0) {
          if($x < ($xs * sqrt($st))) {
	    $mustprint = 0;
	  } else {
	    if($x > ($xe / sqrt($st))) {
	      $mustprint = 0;
	    }
	  }
	} else {
	  if($x < ($xs / sqrt($st))) {
	    $mustprint = 0;
	  } else {
	    if($x < ($xs * sqrt($st))) {
	      $mustprint = 0;
	    }
	  }
	}
      } else {
        if($x < ($xs + 0.5 * $st)) {
	  $mustprint = 0;
	} else {
	  if($x > ($xe - 0.5 * $st)) {
	    $mustprint = 0;
	  }
	}
      }
      if($mustprint) {
        my $co = $ax->value_to_coord($x);
	print $fh "\\pgfpathmoveto{";
	if($xyflag) {
	  $self->write_point($self->{'x3bp'}, $co);
	} else {
	  $self->write_point($co, $self->{'y3bp'});
	}
	print $fh "}\n\\pgfpathlineto{";
	if($xyflag) {
	  $self->write_point($self->{'x4bp'}, $co);
	} else {
	  $self->write_point($co, $self->{'y4bp'});
	}
	print $fh "}\n\\pgfusepath{stroke}\n";
      }
    }
  }
  return $self;
}


sub draw_grid
{
  my $self = shift;
  $self->draw_axis_grid($self->{'b'}, 0);
  $self->draw_axis_grid($self->{'l'}, 1);
  return $self;
}



sub text_label_number
{
  my $self = shift;
  my $x = shift;	# X coordinate
  my $y = shift;	# Y coordinate
  my $p = shift;	# Position string
  my $n = shift;	# NumberPrinter
  my $v = shift;	# Value
  my $vt;
  my $pa;
  my $pb;
  my $fh = $self->{'f1'};
  print $fh "\\pgftext[$p,at={";
  $self->write_point($x, $y);
  print $fh "}]{";
  if(defined($n)) {
    $n->write_number($fh, $v);
  } else {
    $vt = sprintf("%g", $v);
    if("$vt" =~ /(.*)\.(.*)/o) {
      $pa = $1; $pb = $2;
      print $fh "$pa" . $self->{'decsgn'} . "$pb";
    } else {
      print $fh "$vt";
    }
  }
  print $fh "}\n";
  return $self;
}



sub text_label
{
  my $self = shift;
  my $x = shift;	# X coordinate
  my $y = shift;	# Y coordinate
  my $p = shift;	# Position string
  my $t = shift;	# NumberPrinter
  my $fh = $self->{'f1'};
  print $fh "\\pgftext[$p,at={";
  $self->write_point($x, $y);
  print $fh "}]{$t}\n";
  return $self;
}


sub tics_for_axis
{
  my $self = shift;
  my $ax = shift;
  if(($ax->{'used'}) && ($ax->{'ts'} > 0.0)) {
    my $fh = $self->{'f1'};
    my $co = $self->{'y2bp'};
    my $c2 = 0.0;
    my $xyflag = 0;
    my $position = "base";
    my $xs = $ax->{'min'};
    my $xe = $ax->{'max'};
    my $st = $ax->{'ts'};
    my $num = 0;	# Number of attempts
    my $in = 0;		# Inner values
    my $ci = 0;		# Current inner value
    my $x = 0.0;	# Current x to handle
    my $cc = 1;		# Flag: Can continue
    my $ca = 0;		# Flag: Candidate
    my $mut = 0;	# Flag: Must use this
    my $np = LaTeX::PGF::Diagram2D::NumberPrinter->new();
    my $pnp = $np;
    if($ax->{'t'}) {
      $pnp = undef;
    }
    $np->init();
    if($ax->{'n'} eq 'l') {
      $xyflag = 1; $co = $self->{'x2bp'}; $position = "right";
    }
    if($ax->{'n'} eq 'r') {
      $xyflag = 1; $co = $self->{'x5bp'}; $position = "right";
    }
    if($ax->{'n'} eq 't') {
      $co = $self->{'y5bp'};
    }
    for(my $passno = 0; $passno < 3; $passno++) {
      # first value
      if($passno == 1) {
        $np->add_number($xs);
      }
      if($passno == 2) {
        $c2 = $ax->value_to_coord($xs);
	if($xyflag) {
	  $self->text_label_number($co, $c2, $position, $pnp, $xs);
	} else {
	  $self->text_label_number($c2, $co, $position, $pnp, $xs);
	}
      }
      # last value
      if($passno == 1) {
        $np->add_number($xe);
      }
      if($passno == 2) {
        $c2 = $ax->value_to_coord($xe);
	if($xyflag) {
	  $self->text_label_number($co, $c2, $position, $pnp, $xe);
	} else {
	  $self->text_label_number($c2, $co, $position, $pnp, $xe);
	}
      }
      # values in the middle
      $x = $xs; $cc = 1; $num = 0; $ci = 0;
      while($cc) {
        if($num++ > 1000) {
	  $cc = 0;
	}
	$ca = 0;
	if($xe > $xs) {		# Normal scale
	  if($ax->{'t'}) {
	    if($st > 1.0) {
	      $x = $x * $st;
	      if($x > ($xs * sqrt($st))) {
	        if($x < ($xe / sqrt($st))) {
		  $ca = 1;
		} else {
		  $cc = 0;
		}
	      }
	    } else {
	      $x = $x / $st;
	      if($x > ($xs / sqrt($st))) {
	        if($x < ($xe * sqrt($st))) {
		  $ca = 1;
		} else {
		  $cc = 0;
		}
	      }
	    }
	  } else {
	    $x = $x + $st;
	    if($x > ($xs + 0.5 * $st)) {
	      if($x < ($xe - 0.5 * $st)) {
	        $ca = 1;
	      } else {
	        $cc = 0;
	      }
	    }
	  }
	} else {		# Inverted scale
	  if($ax->{'t'}) {
	    if($st > 1.0) {
	      $x = $x / $st;
	      if($x < ($xs / sqrt($st))) {
	        if($x > ($xe * sqrt($st))) {
		  $ca = 1;
		} else {
		  $cc = 0;
		}
	      }
	    } else {
	      $x = $x * $st;
	      if($x < ($xs * sqrt($st))) {
	        if($x > ($xe / sqrt($st))) {
		  $ca = 1;
		} else {
		  $cc = 0;
		}
	      }
	    }
	  } else {
	    $x = $x - $st;
	    if($x < ($xs - 0.5 * $st)) {
	      if($x > ($xe + 0.5 * $st)) {
	        $ca = 1;
	      } else {
	        $cc = 0;
	      }
	    }
	  }
	}
	if($ca) {
          if($passno == 0) {
	    $in++;
          } else {
	    $mut = 1;
	    if(defined($ax->{'u'})) {
	      if($ax->{'omit'}) {
	        if($ci >= ($in - $ax->{'omit'})) {
		  $mut = 0;
		}
	      }
	    }
	    if($mut) {
              if($passno == 1) {
	        $np->add_number($x);
              }
              if($passno == 2) {
	        $c2 = $ax->value_to_coord($x);
		if($xyflag) {
		  $self->text_label_number($co, $c2, $position, $pnp, $x);
		} else {
		  $self->text_label_number($c2, $co, $position, $pnp, $x);
		}
              }
	    }
          }
	  $ci++;
	}
      }
    }
    if(defined($ax->{'u'})) {
      $x = (1.0 * $in + 0.5 - 0.5 * $ax->{'omit'})/(1.0 + $in);
      if($xyflag) {
        $x = $self->{'y3bp'} + $x * ($self->{'y4bp'} - $self->{'y3bp'});
	$self->text_label($co, $x, $position, $ax->{'u'});
      } else {
        $x = $self->{'x3bp'} + $x * ($self->{'x4bp'} - $self->{'x3bp'});
	$self->text_label($x, $co, $position, $ax->{'u'});
      }
    }
  }
  return $self;
}



sub draw_tics
{
  my $self = shift;
  $self->tics_for_axis($self->{'b'});
  $self->tics_for_axis($self->{'l'});
  $self->tics_for_axis($self->{'r'});
  $self->tics_for_axis($self->{'t'});
  return $self;
}



sub arrow
{
  my $self = shift;
  my $x0 = shift;
  my $y0 = shift;
  my $d = shift;
  my $fh = $self->{'f1'};
  my $x1 = $x0 + 23.811;
  my $y1 = $y0;
  my $x2 = $x0 + 28.346;
  my $y2 = $y0;
  my $x3 = $x0 + 19.843;
  my $y3 = $y0 + 2.1;
  my $x4 = $x3;
  my $y4 = $y0 - 2.1;
  if($d == 1) {
    $x1 = $x0; $y1 = $y0 + 23.811;
    $x2 = $x0; $y2 = $y0 + 28.346;
    $x3 = $x0 - 2.1; $y3 = $y0 + 19.843;
    $x4 = $x0 + 2.1; $y4 = $y3;
  } else {
    if($d == 2) {
      $x1 = $x0 - 23.811; $y1 = $y0;
      $x2 = $x0 - 28.346; $y2 = $y0;
      $x3 = $x0 - 19.843; $y3 = $y0 + 2.1;
      $x4 = $x3; $y4 = $y0 - 2.1;
    } else {
      if($d == 3) {
        $x1 = $x0; $y1 = $y0 - 23.811;
        $x2 = $x0; $y2 = $y0 - 28.346;
        $x3 = $x0 - 2.1; $y3 = $y0 - 19.843;
        $x4 = $x0 + 2.1; $y4 = $y3;
      }
    }
  }
  print $fh "\\pgfpathmoveto{";
  $self->write_point($x0, $y0);
  print $fh "}\n\\pgfpathlineto{";
  $self->write_point($x1, $y1);
  print $fh "}\n\\pgfusepath{stroke}\n";
  print $fh "\\pgfpathmoveto{";
  $self->write_point($x2, $y2);
  print $fh "}\n\\pgfpathlineto{";
  $self->write_point($x3, $y3);
  print $fh "}\n\\pgfpathlineto{";
  $self->write_point($x4, $y4);
  print $fh "}\n\\pgfpathclose\n\\pgfusepath{fill}\n";
  return $self;
}



sub axis_arrows_and_units
{
  my $self = shift;
  my $ax = shift;
  my $fh = $self->{'f1'};
  if($ax->{'used'}) {
    if(defined($ax->{'l'})) {
      my $xyflag = 0;
      my $co = $self->{'y1bp'};
      my $m = $self->{'x3bp'} + 0.5 * ($self->{'x4bp'} - $self->{'x3bp'});
      if($ax->{'n'} eq 'l') {
        $xyflag = 1;
	$co = $self->{'x1bp'};
	$m = $self->{'y3bp'} + 0.5 * ($self->{'y4bp'} - $self->{'y3bp'});
      }
      if($ax->{'n'} eq 'r') {
        $xyflag = 1;
	$co = $self->{'x6bp'};
	$m = $self->{'y3bp'} + 0.5 * ($self->{'y4bp'} - $self->{'y3bp'});
      }
      if($ax->{'n'} eq 't') {
        $co = $self->{'y6bp'};
      }
      if(defined($ax->{'color'})) {
        $self->set_color($ax->{'color'});
      }
      if($xyflag) {
        if($ax->{'max'} > $ax->{'min'}) {
	  $self->text_label($co, ($m - 2.8346), "top", $ax->{'l'});
	  $self->arrow($co, ($m + 2.8346), 1);
	} else {
	  $self->text_label($co, ($m + 2.8346), "bottom", $ax->{'l'});
	  $self->arrow($co, ($m - 2.8346), 3);
	}
      } else {
        if($ax->{'max'} > $ax->{'min'}) {
	  $self->text_label(($m - 2.8346), $co, "right", $ax->{'l'});
	  $self->arrow(($m + 2.8346), $co, 0);
	} else {
	  $self->text_label(($m + 2.8346), $co, "left", $ax->{'l'});
	  $self->arrow(($m - 2.8346), $co, 2);
	}
      }
    }
  }
  return $self;
}



sub arrows_and_units
{
  my $self = shift;
  $self->axis_arrows_and_units($self->{'b'});
  $self->axis_arrows_and_units($self->{'l'});
  $self->axis_arrows_and_units($self->{'r'});
  $self->axis_arrows_and_units($self->{'t'});
  return $self;
}



sub draw_polylines_and_labels
{
  my $self = shift;
  my $ar = $self->{'contents'};
  my $ai = $self->{'nco'};
  my $or;
  for(my $i = 0; $i < $ai; $i++) {
    $or = $ar->[$i];
    $or->plot();
  }
  return $self;
}



sub draw_plots
{
  my $self = shift;
  my $ap = $self->{'p'};
  my $np = $self->{'np'};
  my $pref;
  for(my $i = 0; $i < $np; $i++) {
    $pref = $ap->[$i];
    $pref->plot_to($self);
  }
  return $self;
}


sub write_image_contents
{
  my $self = shift;
  my $fh = $self->{'f1'};
  # Bounding box
  $self->write_clip(
    floor($self->{'x0bp'}), floor($self->{'y0bp'}),
    ceil($self->{'x7bp'}), ceil($self->{'y7bp'})
  );
  # Grid
  print $fh "\% Grid\n";
  $self->setlinewidth_mm(0.05);
  $self->set_color('black');
  $self->draw_grid();
  # Tics
  print $fh "\% Scale values\n";
  $self->draw_tics();
  $self->begin_pgfscope();
  $self->write_clip(
    $self->{'x3bp'}, $self->{'y3bp'},
    $self->{'x4bp'}, $self->{'y4bp'}
  );
  # Curves
  print $fh "\% Curves\n";
  $self->setlinewidth_mm(0.2);
  $self->draw_plots();
  $self->end_pgfscope();
  # Polylines and arrow
  print $fh "\% Text labels and polylines\n";
  $self->draw_polylines_and_labels();
  # Frame
  print $fh "\% Frame\n";
  $self->set_color('black');
  $self->setlinewidth_mm(0.1);
  $self->write_rect(
    $self->{'x3bp'}, $self->{'y3bp'},
    $self->{'x4bp'}, $self->{'y4bp'}
  );
  print $fh "\\pgfusepath{stroke}\n";
  # Arrows and Labels
  print $fh "\% Axis labels and arrows\n";
  $self->setlinewidth_mm(0.2);
  $self->arrows_and_units();
}


sub write
{
  my $self = undef;
  my $fh = undef;
  if($#_ < 1) {
  } else {
    $self = shift; $self->{'fn1'} = shift;
    $self->{'ftf'} = 0;
    if($self->{'fn1'} =~ /.*\.[Tt][Ee][Xx]/o) {
      $self->{'ftf'} = 1;
    }
    if(open($fh, '>', $self->{'fn1'})) {
      $self->{'f1'} = $fh;
      $self->prepare_for_output();
      if($self->{'ftf'}) {
        my $utfflag = 0;
        if(exists($ENV{"LANG"})) {
	  if($ENV{"LANG"} =~ /\.[Uu][Tt][Ff]\-8/o) {
	    $utfflag = 1;
	  }
        }
        print $fh "\\documentclass[" . $self->{'fs'} . "pt]{article}\n";
	if($utfflag) {
	  print $fh "\\usepackage[utf8]{inputenc}\n";
	} else {
	  print $fh "\\usepackage[latin1]{inputenc}\n";
	}
	print $fh "\\usepackage[T1]{fontenc}\n";
	print $fh "\\usepackage{textcomp}\n";
	print $fh "\\usepackage{mathptmx}\n";
	print $fh "\\usepackage[scaled=.92]{helvet}\n";
	print $fh "\\usepackage{courier}\n";
	print $fh "\\usepackage[intlimits]{amsmath}\n";
	print $fh "\\usepackage{graphicx}\n";
	print $fh "\\usepackage{color}\n";
        print $fh "\\usepackage{ifpdf}\n";
	print $fh "\\usepackage{fancybox}\n";
	print $fh "\\usepackage{pgfcore}\n";
        print $fh "\\setlength{\\paperwidth}{"
              . ceil($self->{'x7bp'}) . "bp}\n";
        print $fh "\\setlength{\\paperheight}{"
              . ceil($self->{'y7bp'}) . "bp}\n";
        print $fh "\\pagestyle{empty}\n";
        print $fh "\\setlength{\\voffset}{-1in}\n";
        print $fh "\\setlength{\\topmargin}{0mm}\n";
        print $fh "\\setlength{\\headheight}{0mm}\n";
        print $fh "\\setlength{\\headsep}{0mm}\n";
        print $fh "\\setlength{\\topskip}{0mm}\n";
        print $fh "\\setlength{\\hoffset}{-1in}\n";
        print $fh "\\setlength{\\oddsidemargin}{0mm}\n";
        print $fh "\\setlength{\\evensidemargin}{0mm}\n";
        print $fh "\\setlength{\\marginparwidth}{0mm}\n";
        print $fh "\\setlength{\\marginparsep}{0mm}\n";
        print $fh "\\setlength{\\textwidth}{\\paperwidth}\n";
        print $fh "\\setlength{\\textheight}{\\paperheight}\n";
        print $fh "\\setlength{\\parskip}{0mm}\n";
        print $fh "\\setlength{\\parindent}{0mm}\n";
        print $fh "\\ifpdf\n";
        print $fh "\\setlength{\\pdfpagewidth}{\\paperwidth}\n";
        print $fh "\\setlength{\\pdfpageheight}{\\paperheight}\n";
        print $fh "\\fi\n";
        print $fh "\\begin{document}%\n";
      }

      print $fh "\\begin{pgfpicture}\n";
      $self->write_image_contents();
      print $fh "\\end{pgfpicture}\%\n";

      if($self->{'ftf'}) {
        print $fh "\\end{document}\n";
      }

      close($fh);
    }
    $self->{'ftf'} = 0;
  }
  return $self;
}



sub set_font_size
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$diagram->set_font_size(fontsize)";
  } else {
    $self = shift; $self->{'fs'} = shift;
  }
  return $self;
}



sub axis
{
  my $back = undef;
  if($#_ < 1) {
    croak "Usage: \$diagram->axis(name)";
  } else {
    my $self = shift;
    my $name = shift;
    if(("$name" eq "b") || ("$name" eq "bottom")) { $back = $self->{'b'}; }
    if(("$name" eq "l") || ("$name" eq "left")) { $back = $self->{'l'}; }
    if(("$name" eq "r") || ("$name" eq "right")) { $back = $self->{'r'}; }
    if(("$name" eq "t") || ("$name" eq "top")) { $back = $self->{'t'}; }
    if(!defined($back)) {
      croak "ERROR: Wrong axis name \"$name\"! Allowed names:\n"
            . "  'b' (bottom), 'l', (left), 'r' (right) or 't' (top).";
    }
  }
  return $back;
}



sub plot
{
  my $back = undef;
  if($#_ < 2) {
    croak "Usage: \$diagram->plot(axisname,axisname)";
  } else {
    my $self = shift;
    my $an1 = shift;
    my $an2 = shift;
    my $ax = undef; my $ay = undef;
    foreach my $i ($an1, $an2) {
      my $nok = 0;
      if(("$i" eq "b") || ("$i" eq "bottom")) { $ax = $self->{'b'}; $nok = 1; }
      if(("$i" eq "l") || ("$i" eq "left")) { $ay = $self->{'l'}; $nok = 1; }
      if(("$i" eq "r") || ("$i" eq "right")) { $ay = $self->{'r'}; $nok = 1; }
      if(("$i" eq "t") || ("$i" eq "top")) { $ax = $self->{'t'}; $nok = 1; }
      if(!$nok) {
        croak "ERROR: Wrong axis name \"$i\"! Allowed names:\n"
              . "  'b' (bottom), 'l', (left), 'r' (right) or 't' (top).";
      }
    }
    if(defined($ax) && defined($ay)) {
      my $ar = $self->{'p'};
      my $an = $self->{'np'};
      $back = LaTeX::PGF::Diagram2D::Plot->new();
      $ar->[$an++] = $back;
      $self->{'np'} = $an;
      $back->{'ax'} = $ax; $back->{'ay'} = $ay;
      $ax->{'used'} = 1; $ay->{'used'} = 1;
      $back->{'debug'} = $self->{'debug'};
    } else {
      croak "ERROR: One x-axis and one y-axis needed!";
    }
  }
  return $back;
}



sub copy_plot
{
  my $back = undef;
  if($#_ < 1) {
    croak "Usage: \$diagram->copy_plot(plot)";
  } else {
    my $self = shift; my $src = shift;
    my $ar = $self->{'p'};
    my $an = $self->{'np'};
    $back = LaTeX::PGF::Diagram2D::Plot->new();
    foreach my $k(keys %$src) {
      $back->{"$k"} = $src->{"$k"};
    }
    $ar->[$an++] = $back;
    $self->{'np'} = $an;
  }
  return $back;
}



sub label
{
  my $back = undef;
  if($#_ < 3) {
    croak "Usage: \$diagram->label(xaxis, yaxis, x, y, text[, position])";
  } else {
    my $self = shift;
    my $xan = shift;
    my $yan = shift;
    my $x = shift;
    my $y = shift;
    my $t = shift;
    my $p = undef;
    if($#_ >= 0) {
      $p = shift;
    }
    my $ax = undef; my $ay = undef;
    if(("$xan" eq "b") || ("$xan" eq "bottom")) { $ax = $self->{'b'}; }
    if(("$xan" eq "l") || ("$xan" eq "left")) { $ay = $self->{'l'}; }
    if(("$xan" eq "r") || ("$xan" eq "right")) { $ay = $self->{'r'}; }
    if(("$xan" eq "t") || ("$xan" eq "top")) { $ax = $self->{'t'}; }
    if(("$yan" eq "b") || ("$yan" eq "bottom")) { $ax = $self->{'b'}; }
    if(("$yan" eq "l") || ("$yan" eq "left")) { $ay = $self->{'l'}; }
    if(("$yan" eq "r") || ("$yan" eq "right")) { $ay = $self->{'r'}; }
    if(("$yan" eq "t") || ("$yan" eq "top")) { $ax = $self->{'t'}; }
    if((defined($ax) && defined($ay))) {
      if(defined($p)) {
        $back = LaTeX::PGF::Diagram2D::Label->new($self, $ax, $ay, $x, $y, $t, $p);
      } else {
        $back = LaTeX::PGF::Diagram2D::Label->new($self, $ax, $ay, $x, $y, $t);
      }
      my $ar = $self->{'contents'};
      my $ai = $self->{'nco'};
      $ar->[$ai++] = $back;
      $self->{'nco'} = $ai;
    } else {
      croak "ERROR: One x- and one y-axis is needed!";
    }
  }
  return $back;
}



sub polyline
{
  my $back = undef;
  if($#_ < 3) {
    croak "Usage: \$diagram->polyline(xaxis,yaxis,pointsarrayref)";
  } else {
    my $self = shift;
    my $xan = shift;
    my $yan = shift;
    my $pref = shift;
    my $ax = undef; my $ay = undef;
    if(("$xan" eq "b") || ("$xan" eq "bottom")) { $ax = $self->{'b'}; }
    if(("$xan" eq "l") || ("$xan" eq "left")) { $ay = $self->{'l'}; }
    if(("$xan" eq "r") || ("$xan" eq "right")) { $ay = $self->{'r'}; }
    if(("$xan" eq "t") || ("$xan" eq "top")) { $ax = $self->{'t'}; }
    if(("$yan" eq "b") || ("$yan" eq "bottom")) { $ax = $self->{'b'}; }
    if(("$yan" eq "l") || ("$yan" eq "left")) { $ay = $self->{'l'}; }
    if(("$yan" eq "r") || ("$yan" eq "right")) { $ay = $self->{'r'}; }
    if(("$yan" eq "t") || ("$yan" eq "top")) { $ax = $self->{'t'}; }
    if(defined($ax) && defined($ay)) {
      if($#$pref >= 3) {
        $back = LaTeX::PGF::Diagram2D::Polyline->new($self, $ax, $ay, $pref);
        my $ar = $self->{'contents'};
        my $ai = $self->{'nco'};
        $ar->[$ai++] = $back;
        $self->{'nco'} = $ai;
      } else {
        croak "ERROR: At least 2 points are needed!";
      }
    } else {
      croak "ERROR: One x- and one y-axis is needed!";
    }
  }
  return $back;
}



sub value_to_coord
{
  my $back = 0.0;
  my $self = shift;
  my $ax = shift;
  my $ay = shift;
  my $v = shift;
  my $i = shift;
  if($i % 2) {
    if(("$v" eq "t") || ("$v" eq "top")) {
      $back = $self->{'y5bp'};
    } else {
      if(("$v" eq "b") || ("$v" eq "bottom")) {
        $back = $self->{'y2bp'};
      } else {
        $back = $ay->value_to_coord($v);
      }
    }
  } else {
    if(("$v" eq "l") || ("$v" eq "left")) {
      $back = $self->{'x2bp'};
    } else {
      if(("$v" eq "r") || ("$v" eq "right")) {
        $back = $self->{'x5bp'};
      } else {
        $back = $ax->value_to_coord($v);
      }
    }
  }
  return $back;
}



sub set_debug
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$diagram->set_debug(flag)";
  } else {
    $self = shift; $self->{'debug'} = shift;
    my $ar = $self->{'p'};
    my $ai = $self->{'np'};
    my $pref;
    for(my $i = 0; $i < $ai; $i++) {
      $pref = $ar->[$i];
      $pref->{'debug'} = $self->{'debug'};
    }
  }
  return $self;
}


1;
__END__

=head1 NAME

LaTeX::PGF::Diagram2D - Perl extension for drawing 2D diagrams.

=head1 SYNOPSIS

  use LaTeX::PGF::Diagram2D;
  
  my $Uq = 1.0;
  my $Ri = 4.0;
  
  sub I($)
  {
    my $RL = shift;
    my $back = $Uq / ($Ri + $RL);
    return $back;
  }
  
  # 10 centimeters wide, 6 centimeters high 
  my $d = LaTeX::PGF::Diagram2D->new(10.0, 6.0);
  
  $d->set_font_size(12.0);
  
  # R (on the x axis) is in the range 0 ... 10
  $d->axis('b')->set_linear(0.0, 10.0)->set_grid_step(1.0)
	       ->set_tic_step(1.0);
  # I (on the y axis) is in the range 0 ... 0,3
  $d->axis('l')->set_linear(0.0,  0.3)->set_grid_step(0.05)
	       ->set_tic_step(0.1);
  
  my $p = $d->plot('b', 'l');
  $p->set_xy_fct(\&I);
  
  $d->write("test001a.pgf");


=head1 DESCRIPTION

The module can be used to draw 2D diagrams following DIN 461 (a german
standard) for use with LaTeX.
The output of the module is a *.pgf file. In your LaTeX source make sure
to have

  \usepackage{pgf}

in the preamble. The *.pgf files can be used with both latex/dvips and
pdflatex.

Use code like

  \begin{figure}%
  {\centering%
  \input{file.pgf}\caption{My caption}\label{blablablubb}%
  }%
  \end{figure}

to include the produced graphics.

=head1 EXPORT

None by default.

=head1 CLASSES

The following classes are involved:

=over	4

=item	LaTeX::PGF::Diagram2D

represents a diagram.

=item	LaTeX::PGF::Diagram2D::Axis

represents one axis of the diagram.

=item	LaTeX::PGF::Diagram2D::Plot

represents one item to plot (a function or a point set).

=back

=head1 Methods

=head2 Constructor

LaTeX::PGF::Diagram2D->new(width, height)

creates a new diagram object. Width and height of the canvas are specified
in centimeters.

=head2 Setup

set_font_size(size)

specifies the font size of the LaTeX document in point.

axis(name)

returns a reference to the LaTeX::PGF::Diagram2D::Axis object for the name.
The name can be one of ``bottom'', ``left'', ``right'' or ``top'' or
one of the abbreviations ``b'', ``l'', ``r'' or ``t''.
The object reference can be used to invoke the setup methods for the
axis, see LaTeX::PGF::Diagram2D::Axis.

=head2 Create plot objects

plot(xaxisname, yaxisname)

creates a new plot object and saves it to the diagram. A referernce to the
LaTeX::PGF::Diagram2D::Plot object is returned, this reference can be used to
configure the plot object, see LaTeX::PGF::Diagram2D::Plot.

copy_plot(plotobjectreference)

duplicates a plot object and returns the reference to the new object.
This is useful if you want to print i.e. a point set with an interpolation
curve, so your need one object for the curve and another one for the dots.

=head2 Additional graphics objects

label(xaxisname, yaxisname, x, y, text [, anchor ])

adds a text label. The axis names decide which axis the coordinates belong
to. The optional anchor argument is ``left'', ``right'', ``top'', ``bottom''
or a comma-separated combination of a horizontal and a vertical position.

polyline(xaxisname, yaxisname, arrayreference)

creates a polyline object. The third parameter is a reference to an array
containing the x- and y-coordinates for each point.

=head2 Output

write(filename)

writes the graphics to the named file. If the filename suffix is ``.tex''
an entire LaTeX file is written, a file containing a PGF image otherwise.

=head1 SEE ALSO

LaTeX::PGF::Diagram2D::Axis.pm
LaTeX::PGF::Diagram2D::Label.pm
LaTeX::PGF::Diagram2D::Plot.pm
LaTeX::PGF::Diagram2D::Polyline.pm

=head1 AUTHOR

Dirk Krause, E<lt>krause@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dirk Krause

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

