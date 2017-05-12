package Imager::Plot::Style;

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

use vars qw (%colors %styles);

%colors = (
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



sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %opts = @_;


  my %style = ();

  if ($opts{string}) {
    %style = %{style_from_string($opts{string})};
  } elsif (@opts{line,circle}) {
    %style = %opts;
  } else {
    %style = (
	      line=>{ color => Imager::Color->new("#0000FF"), antialias=>1 }
	      );
  }

  my $l = $style{'line'};
  $l->{'width'} = 1 if defined $l and !exists $l->{'width'};

  my $self  = \%style;
  bless ($self, $class);
  return $self;
}






1;
__END__

put docs here!
