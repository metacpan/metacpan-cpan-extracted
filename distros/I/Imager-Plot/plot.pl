#!/usr/bin/perl -w


use strict qw( vars );
use lib qw (blib/arch blib/lib);
use IO::File;
use Getopt::Long;

use Imager::Plot;
use Imager qw(:handy);


my $base = $ENV{HOME}."/.hackplot";
my $globalfont = "$base/ImUgly.ttf";

Imager::init(log=>"$base/logfile");


use Getopt::Long;
my ($title, $xlabel, $ylabel, @xcol, @ycol, @col);
my ($xstring, $ystring, $string);
my $r = GetOptions("title=s",  \$title,
		   "xlabel=s", \$xlabel,
		   "ylabel=s", \$ylabel,
		   "xcol=s",   \$xstring,
		   "ycol=s",   \$ystring,
		   "col=s",    \$string,
		   "font=s",   \$globalfont);




die usage() unless @ARGV==2;
my ($datafile, $outfile) = @ARGV;

my $file;
if ($datafile eq "-") {
  $file = \*STDIN;
} else {
  $file = new IO::File $datafile, "r" or die "Cannot open file $datafile: $!\n";
}
my @data = get_data_columns($file);


my ($x, $y);

if ($string) {
  my @col = map { $_-1 } split(/,/, $string);

  my $xcol = shift @col;
  my @x;
  if ($xcol == -1) {
    @x = 1..@data;
  } else {
    @x = map { $_->[$col[0]] } @data;
  }
  my $cc;
  $y=[];
  for $cc (@col) {
    push(@$y, [map { $_->[$cc] } @data ]);
  }
  $x = [map { [@x] } @$y ];

} elsif (@xcol and @ycol) {
  print "XXX";



} else {
  if (@{$data[0]} > 1) {
    my @ri = sort { $data[$a]->[0] <=> $data[$b]->[0] } 0..(@data-1);
    $x = [[map { $_->[0] } @data[@ri]]];
    $y = [[map { $_->[1] } @data[@ri]]];
  } else {
    $x = [[1..@data]];
    $y = [[map { $_->[0] } @data]];
  }
}


$title  = "" unless defined ($title);
$xlabel = "" unless defined ($xlabel);
$ylabel = "" unless defined ($ylabel);



simple_plot($outfile, $x, $y, $xlabel, $ylabel, $title);

sub get_data_columns {
  my $fh = shift;

  my @rawdata = <$fh>;
  chomp(@rawdata);
  my @data;

  for (@rawdata) {		# DO WHAT I MEAN!
    my @t = m/(?::|,|\s|^)((?:[+-]?)(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?)(?=:|,|\s|$)/g;
    push(@data, \@t);
										 }

    my %hist;
    $hist{@$_+0}++ for @data;

    my $m = 0;
    my $k;

    for (keys %hist) {
      if ($hist{$_} > $m) {
	$m = $hist{$_};
	$k = $_;
      }
    }

    @data = grep { @$_+0 == $k } @data; # Skip things with a different number of columns
    return @data;
  }



  sub simple_plot {
    my ($file, $x, $y, $xlabel, $ylabel, $title) = @_;

    my $img = Imager->new(xsize=>700, ysize => 500);
    my $plot = Imager::Plot->new(Width  => 600,
				 Height => 400,
				 LeftMargin   => 30,
				 BottomMargin => 30,
				 GlobalFont => $globalfont);

    for (0..(@$x-1)) {
      $plot->AddDataSet(X  => $x->[$_], Y => $y->[$_]);
    }

    $plot->Set(Xlabel=> $xlabel );
    $plot->Set(Ylabel=> $ylabel );
    $plot->Set(Title => $title );


    $img->box(filled=>1, color=>Imager::Color->new(255,255,255));
    $plot->Render(Image => $img, Xoff =>80, Yoff => 450);
    $img->write(file => $file) or die $img->errstr;
  }


sub usage {
  my $rs = "";
  $rs .= "Usage: $0 OPTIONS datafile outputfile\n\n";
  $rs .= "\tOPTIONS: title, xlabel, ylabel, col, xcol, ycol, font\n\n";

  $rs .= "\tdatafile is the file to read input data from.  The program\n";
  $rs .= "\ttries to extract only numerical fields and throws out lines that\n";
  $rs .= "\thave the wrong number of colunms.  Specifying - reads from standard\n";
  $rs .= "\tinput.  Note that -- - is really needed to avoid a warning from Getopts.\n\n";

  $rs .= "\toutputfile is the file of the output image.  This must have a valid\n";
  $rs .= "\textension for Imager to know what format to use.\n\n";


  $rs .= "\tEach option is followed by a string.  Standard Getopts parameters are\n";
  $rs .= "\tused.  So -title foo, --title foo, --title=foo are all valid\n\n";


  $rs .= "\ttitle:  Title of graph\n";
  $rs .= "\txlabel: X-axis label\n";
  $rs .= "\tylabel: Y-axis label\n";
  $rs .= "\tcol:    Comma seperated list of columns to use for datasets.\n";
  $rs .= "\t        The first entry in the list is taken as the column number\n";
  $rs .= "\t        to use for the X-axis.  An entry in a file is considered to\n";
  $rs .= "\t        be a column entry if it is numerical.  Column 0 is a special\n";
  $rs .= "\t        case which just assigns integers in an increasing linear order.\n";

  $rs .= "\txcol:   Comma seperated list of columns to use for X-axis in datasets.\n";
  $rs .= "\t        ycol must be specified too and the length of the lists must be\n";
  $rs .= "\t        the same.\n";
  $rs .= "\tycol:   Comma seperated list of columns to use for Y-axis in datasets.\n";
  $rs .= "\t        xcol must be specified too.\n\n";

  $rs .= "Examples:\n";
  $rs .= "\tvmstat 1 20 | plot.pl -xlabel seconds \\ \n\t\t -ylabel 'in/cs' -title vmstat -col 0,12,13 -- - vm.ppm\n\n";
  $rs .= "\tplot.pl -xlabel 'line #' -ylabel uid -title 'Password file stuff' \\ \n\t\t -col 0,2 /etc/passwd pwd.png\n";
  $rs .= "\n";

  return $rs;
}

