package Finance::ChartHist;

=head1 NAME

Finance::ChartHist - Perl module to produce historical stock price graphs

=head1 SYNOPSIS

  use Finance::ChartHist;

  $chart = Finance::ChartHist->new( symbols    => "BHP",
                                    start_date => '2001-01-01',
                                    end_date   => '2002-01-01',
                                    width      => 680,
                                    height     => 480
                                  );

  $chart->create_chart();
  $chart->save_chart('chart_name.png', 'png');

=cut

use 5.006;
use strict;
use warnings;
use Carp;

use Finance::QuoteHist;
use GD::Graph::lines;
use Date::Simple;
use POSIX;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Finance::ChartHist ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.03';


sub new
{
  my $that  = shift;
  my $class = ref($that) || $that;
  
  my %params = @_;
  
  my $self = {};
  
  ## Required parameters
  $self->{symbols}    = $params{symbols} or croak "Must provide symbols";
  $self->{start_date} = $params{start_date} or croak "Must provide start_date";
  $self->{end_date}   = $params{end_date} or croak "Must provide end_date";
  
  if($self->{end_date} eq 'today') { $self->{end_date} = today()->format() };
  if($self->{start_date} eq 'today') { $self->{start_date} = today()->format() };

  ## Optional parameters
  $self->{width}      = $params{width} or $self->{width} = 400;
  $self->{height}     = $params{height} or $self->{height} = 300;
  $self->{x_label}    = $params{x_label};
  $self->{y_label}    = $params{y_label};
  
  bless $self, $class;

  $self;
}


sub create_chart
{
  my $self = shift;
  
  ##
  ## Get the data for the graph, returned in a hash reference
  ## $graph_data->{date} contains an array of dates for the graph range
  ## $graph_data->{$symbol} contains an array for the prices on each date
  ##
  my $graph_data = $self->_get_graph_data();
   
  ##
  ## Determine if we are just doing a plain one symbol graph,
  ## or a comparison of multiple symbols.
  ## 
  if(scalar keys %{ $graph_data } > 1) {
    $self->_graph_multiple_symbols($graph_data);
  }
  else {
  	$self->_graph_single_symbol($graph_data);
  }
  
}

sub save_chart
{
	my $self = shift;
	my $name = shift or croak "Need filename!";
	my $format = shift or croak "Need file format!";
	my $graph = $self->{graph};
	local(*OUT);

	open(OUT, ">$name") or 
		die "Cannot open $name for write: $!";
	binmode OUT;
	print OUT $graph->gd->$format();
	close OUT;
}


##
## Private methods
##

sub _get_graph_data
{
  my $self = shift;
  my %graph_data;
  
  ## Get the data
  my $quote = new Finance::QuoteHist(symbols    => $self->{symbols},
                                     start_date => $self->{start_date},
                                     end_date   => $self->{end_date}
                                    );
                                    

  foreach my $row ($quote->quotes()) {
    my ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;
    push @{ $graph_data{$symbol}[0] }, $date;
    push @{ $graph_data{$symbol}[1] }, $close;
    ##print "$symbol, $date, $close\n";
  }
  
  return \%graph_data;
}

sub _graph_single_symbol
{
  my $self = shift;
  my $graph_data = shift or die "No graph data!";

  ## Find the y range of the graph, normalised depending on the
  ## size of the range  
  my ($y_min, $y_max) = $self->_calculate_price_range($graph_data);
  
  ## Figure out how many days our chart will show  
  my $s_date = Date::Simple->new($self->{start_date}) or croak "Couldn't parse start_date";
  my $e_date = Date::Simple->new($self->{end_date}) or croak "Couldn't parse end_date";
  my $date_count = $e_date - $s_date;
  ## Figure out how many x values exist in the chart
  my $tick_count = scalar @{ $graph_data->{$self->{symbols}}[0] };
      
  my ($x_label_skip, $x_label_offset) = $self->_format_x_axis($graph_data,
                                                              $date_count,
                                                              $tick_count);
                                                              
  my $graph = new GD::Graph::lines( $self->{width}, $self->{height});
  
  $graph->set( 
	x_label => $self->{x_label},
	y_label => $self->{y_label},
	title => $self->{symbols},
	y_max_value => $y_max,
	y_min_value => $y_min,
	y_tick_number => $y_max - $y_min,
	x_tick_offset => $x_label_offset,
	x_label_skip => $x_label_skip,
	x_label_position => 1/2,
	box_axis => 0,
	r_margin => 10,
	line_width => 1,

	transparent => 0
  );
  

  $graph->plot(\@{ $graph_data->{$self->{symbols}} });

  ## Keep a copy of the graph  
  $self->{graph} = $graph;
  
}

sub _graph_multiple_symbols
{
  my $self = shift;
  my $graph_data = shift or die "No graph data!";
  
  ## Convert the price data to percentage movements
  $graph_data = $self->_convert_to_percentage_movement($graph_data);
  
  ## Get the percentage range for the data
  my ($y_min, $y_max) = $self->_calculate_price_range($graph_data);
  
  ## Figure out how many days our chart will show  
  my $s_date = Date::Simple->new($self->{start_date}) or croak "Couldn't parse start_date";
  my $e_date = Date::Simple->new($self->{end_date}) or croak "Couldn't parse end_date";
  my $date_count = $e_date - $s_date;
  ## Figure out how many x values exist in the chart
  my $tick_count = scalar @{ $graph_data->{$self->{symbols}[0]}[0] };
      
  my ($x_label_skip, $x_label_offset) = $self->_format_x_axis($graph_data,
                                                              $date_count,
                                                              $tick_count);

  #Produce a title for the graph
  my $title = "";
  foreach (@{ $self->{symbols} }) {
    $title = $title."$_ vs ";
  }
  $title =~ s/ vs $//;
                                                                
  my $graph = new GD::Graph::lines( $self->{width}, $self->{height});
    
  $graph->set( 
	x_label => $self->{x_label},
	y_label => $self->{y_label},
	title => $title,
	y_max_value => $y_max,
	y_min_value => $y_min,
	y_tick_number => $y_max - $y_min,
	x_tick_offset => $x_label_offset,
	x_label_skip => $x_label_skip,
	x_label_position => 1/2,
	box_axis => 0,
	r_margin => 10,
	line_width => 1,

	transparent => 0
  ) or warn $graph->error;
  
  ## Set up the data into the required format
  my @formated_data = ();
  foreach my $symbol (@{ $self->{symbols} }) {
    push @formated_data, $graph_data->{$symbol}[1];
  }
  unshift @formated_data, $graph_data->{$self->{symbols}[0]}[0];

  $graph->plot(\@formated_data) or die $graph->error;
  
  ## Set the legend
  $graph->set_legend( ["BHP", "PIXR"] );

  ## Keep a copy of the graph  
  $self->{graph} = $graph;
  
}

##
## Figure out the range of the share price, and
## calculate what limits we will put on the y-axis
## of the graph
sub _calculate_price_range
{
  my $self = shift;
  my $graph_data = shift or die "No graph data!";
  
  my ($y_max_value, $y_min_value) = (0, 0);
  
  if (scalar keys %{ $graph_data } > 1) {
    foreach my $symbol ( keys %{ $graph_data } ) {
      foreach my $percent (@{ $graph_data->{$symbol}[1] }) {
        if ($percent < $y_min_value) {
          $y_min_value = $percent;
        }

        if ($percent > $y_max_value) {
          $y_max_value = $percent;
        }
      }
    }
  }
  else {
    $y_max_value = $graph_data->{$self->{symbols}}[1][0];
    $y_min_value = $graph_data->{$self->{symbols}}[1][0];
    
    foreach my $price ( @{ $graph_data->{$self->{symbols}}[1] } ) {
      if ($price < $y_min_value) {
        $y_min_value = $price;
      }

      if ($price > $y_max_value) {
        $y_max_value = $price;
      }
    }
  }
  
  ($y_min_value, $y_max_value) = $self->_normalise_range($y_min_value, $y_max_value);
  
  return ($y_min_value, $y_max_value);
}


##
## Format the date values for the x-axis. The number of dates,
## and size of the graph will determine how the x-axis labels
## will be displayed.
##
sub _format_x_axis
{
  my $self = shift;
  my $graph_data = shift or die "No graph_data passed to _format_x_axis()\n";
  my $date_count = shift or die "No date_count passed to _format_x_axis()\n";
  my $tick_count = shift or die "No tick_count passed to _format_x_axis()\n";
  
  my ($x_label_skip, $x_label_offset);
  
  my $month_abv = { "01" => "Jan",
                    "02" => "Feb",
                    "03" => "Mar",
                    "04" => "Apr",
                    "05" => "May",
                    "06" => "Jun",
                    "07" => "Jul",
                    "08" => "Aug",
                    "09" => "Sep",
                    "10" => "Oct",
                    "11" => "Nov",
                    "12" => "Dec" };

  foreach my $key ( keys %{ $graph_data } ) {
    for(my $i = 0;$i < scalar( @{ $graph_data->{$key}[1] } );$i++) {
      ##
      ## Depending on the $date_count and width of the chart,
      ## we will format the dates differently
      ##
      my ($year,$month,$day) = split('/', $graph_data->{$key}[0][$i]);

      ## If less than three months, show 'dd mon' format
      if($date_count < 183) {
        $month = $month_abv->{$month};
        $graph_data->{$key}[0][$i] = "$day$month";
        $x_label_skip = int (40 / ($self->{width} / $tick_count));
        $x_label_offset = $tick_count % $x_label_skip;
      }
      ## If between 3 months and 12 months only show month
      elsif($date_count < 366) {
        $month = $month_abv->{$month};
        $year  =~ s/\d\d(\d\d)/$1/;
        $graph_data->{$key}[0][$i] = "$month$year";
        $x_label_skip = 31;
        $x_label_offset = $tick_count % $x_label_skip;
      }
      ## If between 1 year and 4 years, show month with short year
      elsif($date_count < 1462) {
        $month = $month_abv->{$month};
        $year  =~ s/\d\d(\d\d)/$1/;
        $graph_data->{$key}[0][$i] = "$month$year";
      }
      ## If more than 4 years, go for year only
      else {
        $graph_data->{$key}[0][$i] = "$year";
      }
    }

  }
  
  return ($x_label_skip, $x_label_offset);  
}

sub _convert_to_percentage_movement
{
  my $self = shift;
  my $graph_data = shift or die "No graph data provided to ";
  my $base_price;

  foreach my $symbol ( keys %{ $graph_data } ) {
    $base_price = $graph_data->{$symbol}[1][0];
    for(my $i = 0;$i < scalar @{ $graph_data->{$symbol}[1] };$i++) {
      $graph_data->{$symbol}[1][$i] = $graph_data->{$symbol}[1][$i] / $base_price * 100 - 100;
    }
  }

  return $graph_data;
}

sub _normalise_range
{
  my $self = shift;
  my ($y_min, $y_max) = @_;
  my $range = $y_max - $y_min;
  
  ## If less than 10, round to nearest whole number
  if($range < 10) {
    $y_max = int ($y_max + 1.0);
    $y_min = int ($y_min);
  }
  elsif($range < 20) {
    $y_max = $y_max + ($y_max < 0 ? abs(fmod $y_max, 2) : 2 - (fmod $y_max, 2));
    $y_min = $y_min - ($y_min < 0 ? 2 - abs((fmod $y_min, 2)) : (fmod $y_min, 2));
  }
  elsif($range < 60) {
    $y_max = $y_max + ($y_max < 0 ? abs(fmod $y_max, 5) : 5 - (fmod $y_max, 5));
    $y_min = $y_min - ($y_min < 0 ? 5 - abs((fmod $y_min, 5)) : (fmod $y_min, 5));
  }
  elsif($range < 600) {
    $y_max = $y_max + ($y_max < 0 ? abs(fmod $y_max, 10) : 10 - (fmod $y_max, 10));
    $y_min = $y_min - ($y_min < 0 ? 10 - abs((fmod $y_min, 10)) : (fmod $y_min, 10));
  }
  else {
    $y_max = $y_max + ($y_max < 0 ? abs(fmod $y_max, 100) : 100 - (fmod $y_max, 100));
    $y_min = $y_min - ($y_min < 0 ? 100 - abs((fmod $y_min, 100)) : (fmod $y_min, 100));
  }
  
  return ($y_min, $y_max);
}


1;
__END__

=head1 DESCRIPTION

Finance::ChartHist is a module to produce graphs of historical stock
prices. Single stocks can be graphed over a period of time. Multiple
stocks performance can also be compared over time.

=head1 CONSTRUCTOR

=head2 new(symbols =>, start_date =>, end_date =>, width =>, height =>)

Create a new Finance::ChartHist object.

=head1 INSTANCE METHODS

=head2 create_chart

Fetches the required data and plots the chart.

=head2 save_chart

Save the graph to the file specified.

=head1 AUTHOR

Garth Douglass, E<lt>garth@rubberband.orgE<gt>

=head1 SEE ALSO

Finance::QuouteHist(3), GD::Graph::lines(3).

=head1 COPYRIGHT

Copyright 2002 Garth Douglass <garth@rubberband.org>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
