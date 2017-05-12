package IUP::Canvas::FileVector;
use strict;
use warnings;
use base qw(IUP::Internal::Canvas);
use IUP::Internal::LibraryIup;
use Carp;

sub new {
  my ($class, %args) = @_;
  my $format = $args{format};
  my $filename = $args{filename};
  my $width = $args{width};
  my $height = $args{height};
  my $resolution = $args{resolution};
  my $dpi = $args{dpi};
  
  my $ch;
  if (!$filename) {
    carp "warning: filename parameter not defined for ".__PACKAGE__."->new()";
  }
  elsif (!$format) {
    carp "warning: format parameter not defined for ".__PACKAGE__."->new()";
  }
  elsif (defined $width && $width<0) {
    carp "warning: width parameter is '<=0' for ".__PACKAGE__."->new()";
  }
  elsif (defined $height && $height<0) {
    carp "warning: height parameter is '<=0' for ".__PACKAGE__."->new()";
  }
  elsif ((defined $width && !defined $height) || (!defined $width && defined $height)) {
    carp "warning: none or both height and width parameters have to be defined for ".__PACKAGE__."->new()";
  }
  elsif (defined $dpi && defined $resolution) {
    carp "warning: you cannot define both 'resolution' and 'dpi' parameters for ".__PACKAGE__."->new()";
  }
  elsif (defined $resolution && $resolution<0) {
    carp "warning: resolution parameter is '<=0' for ".__PACKAGE__."->new()";
  }
  elsif (defined $dpi && $dpi<0) {
    carp "warning: dpi parameter is '<=0' for ".__PACKAGE__."->new()";        
  }
  else {
    my $init;
    $resolution = $dpi/25.4 if defined $dpi;
    if ($format eq 'PS') { # http://www.tecgraf.puc-rio.br/cd/en/drv/ps.html
        # "filename -p[paper] -w[width] -h[height] -l[left] -r[right] -b[bottom] -t[top] -s[resolution] [-e] [-g] [-o] [-1] -d[margin]"
        # "%s -p%d -w%g -h%g -l%g -r%g -b%g -t%g -s%d -e -o -1 -g -d%g"        
        $init = $filename;
        $init .= sprintf(" -w%g -h%g", $width, $height) if defined $width && defined $height;        
        $init .= sprintf(" -p%d", $args{paper})     if defined $args{paper};
        $init .= sprintf(" -l%g", $args{left})      if defined $args{left};
        $init .= sprintf(" -r%g", $args{right})     if defined $args{right};
        $init .= sprintf(" -b%g", $args{top})       if defined $args{top};
        $init .= sprintf(" -t%g", $args{bottom})    if defined $args{bottom};
        $init .= sprintf(" -d%g", $args{margin})    if defined $args{margin};
        $init .= sprintf(" -s%d", $resolution) if defined $resolution;
        $init .= " -1" if defined $args{level1};
        $init .= " -g" if defined $args{debug};
        $init .= " -e" if defined $args{eps};
        $init .= " -o" if defined $args{landscape};        
    }
    elsif ($format eq 'SVG') { # http://www.tecgraf.puc-rio.br/cd/en/drv/svg.html
        # "filename [widthxheight] [resolution]"
        # "%s %gx%g %g"
        $init = $filename;
        $init .= sprintf(" %gx%g", $width, $height) if defined $width && defined $height;
        $init .= sprintf(" %g", $resolution) if defined $resolution;
    }
    elsif ($format eq 'CGM') { # http://www.tecgraf.puc-rio.br/cd/en/drv/cgm.html
        # "filename [widthxheight] [resolution] [-t] -p[precision]"
        # "%s %gx%g %g %s"        
        $init = $filename;
        $init .= sprintf(" %gx%g", $width, $height) if defined $width && defined $height;
        $init .= sprintf(" %g", $resolution) if defined $resolution;
        $init .= " -t" if defined $args{codification};
        $init .= sprintf(" -p%d", $args{precision}) if defined $args{precision};
    }
    elsif ($format eq 'DEBUG') { # http://www.tecgraf.puc-rio.br/cd/en/drv/debug.html
        # "filename [widthxheight] [resolution]"
        # "%s %gx%g %g"
        $init = $filename;
        $init .= sprintf(" %gx%g", $width, $height) if defined $width && defined $height;
        $init .= sprintf(" %g", $resolution) if defined $resolution;
    }
    elsif ($format eq 'DGN') { # http://www.tecgraf.puc-rio.br/cd/en/drv/dgn.html 
        # "filename [widthxheight] [resolution] [-f] [-sseedfile]"
        # "%s %gx%g %g %s"        
        $init = $filename;
        $init .= sprintf(" %gx%g", $width, $height) if defined $width && defined $height;
        $init .= sprintf(" %g", $resolution) if defined $resolution;
        $init .= " -f" if defined $args{filling};
        $init .= sprintf(" -s%s", $args{seedfile}) if defined $args{seedfile};
    }
    elsif ($format eq 'DXF') { # http://www.tecgraf.puc-rio.br/cd/en/drv/dxf.html 
        # "filename [widthxheight] [resolution]"
        # "%s %gx%g %g"
        $init = $filename;
        $init .= sprintf(" %gx%g", $width, $height) if defined $width && defined $height;
        $init .= sprintf(" %g", $resolution) if defined $resolution;
    }
    elsif ($format eq 'EMF') { # http://www.tecgraf.puc-rio.br/cd/en/drv/emf.html 
        # "filename widthxheight"
        # "%s %dx%d"
        if (defined $width && defined $height) { #widthxheight - mandatory
          $init = $filename;
          $init .= sprintf(" %dx%d", $width, $height) if defined $width && defined $height;
        }
        else {
          $init = '';
          carp "warning: width and height are mandatory for format=>'EMF'";
        }
    }
    elsif ($format eq 'METAFILE') { # http://www.tecgraf.puc-rio.br/cd/en/drv/mf.html 
        # "filename [widthxheight] [resolution]"
        # "%s %gx%g %g"
        $init = $filename;
        $init .= sprintf(" %gx%g", $width, $height) if defined $width && defined $height;
        $init .= sprintf(" %g", $resolution) if defined $resolution;
    }
    elsif ($format eq 'WMF') { # http://www.tecgraf.puc-rio.br/cd/en/drv/wmf.html 
        # "filename widthxheight [resolution]" 
        # "%s %dx%d %g"
        if (defined $width && defined $height) { #widthxheight - mandatory
          $init = $filename;
          $init .= sprintf(" %dx%d", $width, $height) if defined $width && defined $height;
        }
        else {
          $init = '';
          carp "warning: width and height are mandatory for format=>'WMF'";
        }
    }
    if (defined $init) {
      if ($init ne '') {
        $init .= " $args{raw}"  if defined $args{raw};
        #warn "XXX-DEBUG: type='$format' init='$init'\n";
        $ch = $class->new_from_cnvhandle(IUP::Internal::Canvas::_cdCreateCanvas_BASIC($format, $init));
      }
    }
    else {
      carp "warning: unsupported format '$format' in ".__PACKAGE__."->new()";
    }
  }
  return $ch;
}

1;
