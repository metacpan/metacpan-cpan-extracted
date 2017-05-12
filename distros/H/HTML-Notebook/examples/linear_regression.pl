#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use HTML::Notebook;
use HTML::Notebook::Cell;
use HTML::Table;
use HTML::Show;
use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Scatter;
use PDL;
use PDL::Fit::Linfit;

my $number_of_points = 20;
my $x = sequence $number_of_points;
my $y = $x * (1 + 0.1 * grandom $number_of_points ); # A little bit of noise
my $yfit = linfit1d $y, cat $x; # Model: y = ax

my $notebook = HTML::Notebook->new();
my $text_cell = HTML::Notebook::Cell->new( content => 'Simple linear regression models the relationship between a scalar variable y and another scalar variable x. For example:' );
$notebook->add_cell($text_cell);

my $points = Chart::Plotly::Trace::Scatter->new(x => $x, y => $y, mode => 'markers', name => 'Observations');
my $model = Chart::Plotly::Trace::Scatter->new(x => $x, y => $yfit, name => 'Model');
my $plot = Chart::Plotly::Plot->new( traces => [$points, $model] );
my $chart_cell = HTML::Notebook::Cell->new( content => $plot->html );
$notebook->add_cell($chart_cell);

my $table = HTML::Table->new(-class => "table table-striped table-hover", -head => ['', 'Observations', 'Model'],
	-data => (transpose cat ($x, $y, $yfit))->unpdl);
my $data_cell = HTML::Notebook::Cell->new( content => $table->getTable );
$notebook->add_cell($data_cell);

HTML::Show::show($notebook->render());




