package Imager::Plot::DataSet;

use strict;
use Imager;
use Imager::Plot::Util;

#
# Style string is in the form of one or more
# [rgbckmyo][o-](number)?
#
# examples:
#
# rc is a red circle

#



{
    my %colors = (
		  r=>"red",
		  g=>"green",
		  b=>"blue",
		  c=>"cyan",
		  k=>"black",
		  m=>"magenta",
		  y=>"yellow",
		  o=>"orange",
		  );

    my %styles = ("-","line",
		  o=>"circle",
		 );

sub style_from_string {
  my $string = shift;
  my %style;

  while(s/^([rgbckmyo][ox-])(\d+)?$\s*//) {
    my $key = $styles{$2};
    my $color = $colors{$1};
    my $width = defined $3 ? $colors{$3} : 1;
    $style{$key} = {
		    color=>$color,
		      width=>$width
		   };
  }
  return \%style;
}


}



sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);

  my %opts = @_;
  if ($opts{Y}) {
    $self->{Y} = [@{$opts{Y}}];
    if ($opts{X}) {
      $self->{X} = [@{$opts{X}}];
    } else {
      @{$self->{X}} = 1..@{$opts{Y}};
    }
  }

  if ($opts{XY}) {
    my $nx = $#{$self->{Y}} = $#{$self->{X}} = $#{$opts{XY}};
    ($self->{X}[$_], $self->{Y}[$_]) = @{$opts{XY}->[$_]} for 0..$nx;
  }

  if ($opts{Z}) {
    $self->{Z} = [@{$opts{Z}}];
  }

  $self->{Xmin} = (defined $opts{Xmin}) ? $opts{Xmin} : undef;
  $self->{Ymin} = (defined $opts{Ymin}) ? $opts{Ymin} : undef;
  $self->{Xmax} = (defined $opts{Xmax}) ? $opts{Xmax} : undef;
  $self->{Ymax} = (defined $opts{Ymax}) ? $opts{Ymax} : undef;

  $self->{'style'} = $opts{style} ||
    ($opts{string} ?
     style_from_string($opts{string}) :
     { line=>{ color => Imager::Color->new("#0000FF"), antialias=>1 } }
    );

  my $l = $self->{'style'}->{'line'};
  $l->{'width'} = 1 if defined $l and !exists $l->{'width'};

  $self->{name} = $opts{name} if exists $opts{name};

  return $self;
}

sub data_bbox {
  my $self = shift;
  my @X = minmax(@{$self->{X}});
  my @Y = minmax(@{$self->{Y}});

  $X[0] = $self->{Xmin} if(defined $self->{Xmin});
  $Y[0] = $self->{Ymin} if(defined $self->{Ymin});
  $X[1] = $self->{Xmax} if(defined $self->{Xmax});
  $Y[1] = $self->{Ymax} if(defined $self->{Ymax});

  return (@X, @Y);
}



sub Draw {
  my $self = shift;
  my %opts = @_;
  my $img = $opts{Image};

  my %style = %{$self->{'style'}};

  my @x = $opts{Xmapper}->(@{$self->{X}});
  my @y = $opts{Ymapper}->(@{$self->{Y}});

  my @ox = @{$self->{X}};
  my @oy = @{$self->{Y}};

  if ($style{line}) {
    $img->polyline(x=>\@x,
		   y=>\@y,
		   color=>$style{line}->{color},
		   antialias=>$style{line}->{antialias});

    if($style{line}->{'width'} > 1) {
      my $width = $style{line}->{width} - 1;
      my $pw = 0;

      while($width) {
	my $w = ($width & 1) ? ++$pw : -$pw;
	my @yd = map { $_ + $w } @y;

	$img->polyline(
		       x => \@x,
		       y => \@yd,
		       color => $style{line}->{color},
		       antialias => $style{line}->{antialias}
		      );
	$width--;
      }
    }
  }

  if ($style{area}) {
    # bottom right
    push( @x, $x[scalar(@x)-1] );
    push( @y, $opts{y2} );
    # bottom left
    push( @x, $x[0] );
    push( @y, $opts{y2} );
    $img->polygon(x=>\@x,
		   y=>\@y,
		   color=>$style{area}->{color},
		   antialias=>$style{area}->{antialias});
  }

  if ($style{marker}) {
    die "symbol must be circle for now!\n" unless $style{marker}->{symbol} eq "circle";
    my $l = $#x;
    my $size = $style{marker}->{size} || 1.5;
    for(0..$l) {
      Imager::i_circle_aa($img->{IMG}, 0.5+$x[$_], 0.5+$y[$_], $size, $style{marker}->{color});

      # Non AA version
      #      $img->circle(x => $x[$_],
      #		   y => $y[$_],
      #		   color => $style{marker}->{color},
      #		   r => 3);
    }
  }
  if ($style{code}) {
    # Work defered to a coderef:
    # calling order is:
    # ($DataSet, $xr, $yr, $Xmapper, $Ymapper, $img)
    my $opts = $style{code}->{opts};
    $style{code}->{ref}->($self, \@x, \@y, $opts{Xmapper}, $opts{Ymapper}, $img, $opts);
  }

}





1;
__END__

put docs here!
