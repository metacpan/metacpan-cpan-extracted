package Excel::Writer::XLSX::CDF;
use strict;
use warnings;
use List::MoreUtils qw{first_index};

our $VERSION = '0.03';

=head1 NAME

Excel::Writer::XLSX::CDF - Generates Excel Document with Continuous Distribution Function Chart

=head1 SYNOPSIS

  use Excel::Writer::XLSX::CDF;
  my $writer   = Excel::Writer::XLSX::CDF->new(
                                               chart_title      => "My Title",
                                               group_names_sort => 1,
                                              );
  my @data     = (
                  [group_name_A => 0.11], #group name is used to lable the chart series
                  [group_name_A => 0.21],
                  [group_name_A => 0.31],
                  [group_name_A => 0.41],
                  [group_name_B => 0.07],
                  [group_name_B => 0.13],
                  [group_name_Z => 0.10],
                 );
  my $blob     = $writer->generate(\@data);      #returns Excel File in memory
  my $filename = $writer->generate_file(\@data); #returns Excel File in tmp folder

=head1 DESCRIPTION

Generates Excel Document with Continuous Distribution Function Chart from the supplied data.

=head1 CONSTRUCTOR

=head2 new

  my $writer    = Excel::Writer::XLSX::CDF->new(
                                           chart_title      => "Continuous Distribution Function (CDF)",
                                           chart_y_label    => "Probability",
                                           chart_x_label    => "",
                                           group_names_sort => 0,  #default 0 is in order of appearance in data
                                          );

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) ? ref($this) : $this;
  my $self  = {@_};
  bless $self, $class;
  return $self;
}

=head1 PROPERTIES

=head2 chart_title

Set and returns the title of the Excel chart

Default: Continuous Distribution Function (CDF)

=cut

sub chart_title {
  my $self         = shift;
  $self->{'chart_title'} = shift if @_;
  $self->{'chart_title'} = 'Continuous Distribution Function (CDF)' unless defined $self->{'chart_title'};
  return $self->{'chart_title'};
}

=head2 chart_y_label

Set and returns the Y axis label of the Excel chart

Default: Probability

=cut

sub chart_y_label {
  my $self           = shift;
  $self->{'chart_y_label'} = shift if @_;
  $self->{'chart_y_label'} = 'Probability' unless defined $self->{'chart_y_label'};
  return $self->{'chart_y_label'};
}

=head2 chart_x_label

Set and returns the X axis label of the Excel chart

Default: ""

=cut

sub chart_x_label {
  my $self           = shift;
  $self->{'chart_x_label'} = shift if @_;
  $self->{'chart_x_label'} = '' unless defined $self->{'chart_x_label'};
  return $self->{'chart_x_label'};
}

=head2 chart_legend_display

Set and returns the legend display property for the Excel chart

Default: 1

=cut

sub chart_legend_display {
  my $self           = shift;
  $self->{'chart_legend_display'} = shift if @_;
  $self->{'chart_legend_display'} = 1 unless defined $self->{'chart_legend_display'};
  return $self->{'chart_legend_display'};
}

=head2 chart_colors

Set and returns an array reference of Excel color codes to use for each CDF in group order.  The default color once all colors are used is black.

Default: ['#FF0000', '#800000', '#FFFF00', '#808000', '#00FF00', '#008000', '#00FFFF', '#008080', '#0000FF', '#000080', '#FF00FF', '#800080']

=cut

sub chart_colors {
  my $self          = shift;
  $self->{'chart_colors'} = shift if @_;
  $self->{'chart_colors'} = ['#FF0000', '#800000', '#FFFF00', '#808000',
                       '#00FF00', '#008000', '#00FFFF', '#008080',
                       '#0000FF', '#000080', '#FF00FF', '#800080'] unless $self->{'chart_colors'};
  die('Error: chart_colors property must be and array reference') unless ref($self->{'chart_colors'}) eq 'ARRAY';
  return $self->{'chart_colors'};
}

=head2 group_names_sort

Set and returns the alphabetical sort option for the group names.  A true value Perl-wise will sort the group names before generating the Excel Workbook and a false value will use the order in which the groups were discovered in the data to generate the group names order.

Default: 0

=cut

sub group_names_sort {
  my $self           = shift;
  $self->{'group_names_sort'} = shift if @_;
  $self->{'group_names_sort'} = 0 unless defined $self->{'group_names_sort'};
  return $self->{'group_names_sort'};
}

=head1 METHODS

=head2 generate

Generates an Excel Workbook in memory and returns the Workbook as a data blob stored in the returned scalar variable.

  my $blob = $writer->generate(\@data);

=cut

sub generate {
  my $self   = shift;
  my $data   = shift; #isa [[group=>value], [], [], ...]
  my @groups = ();
  my $series = {};

  foreach my $row (@$data) {
    my $group = $row->[0];
    my $value = $row->[1];
    if (not exists $series->{$group}) {
      push @groups, $group; #keep order
      $series->{$group} = {count=>0, values=>[]};
    }
    $series->{$group}->{'count'}++;
    push @{$series->{$group}->{'values'}}, $value;
  }

  if ($self->group_names_sort) {
    @groups = sort @groups;
  }

  #Open string scalar reference as file handle for Excel::Writer::XLSX to write to
  open my $fh, '>', \my $content or die("Error: Filehandle open error: $!");

  #Object for Excel Workbook
  require Excel::Writer::XLSX;
  my $workbook         = Excel::Writer::XLSX->new($fh);

  #Add a worksheet chart as first tab so it shows when document is opened
  my $chart            = $workbook->add_chart(type=>'scatter', subtype=>'straight');

  #Add worksheet for chart legend groups
  my $worksheet_groups = $workbook->add_worksheet('groups');
  $worksheet_groups->write_string(0, 0, 'Group');
  $worksheet_groups->write_string(0, 1, 'Index');
  $worksheet_groups->write_string(0, 2, 'Count');
  my $group_index      = 0;

  #Colors for data series lines and legend
  my @colors          = @{$self->chart_colors};

  #foreach group add worksheet, data and chart series
  my @stats_groups    = ();

  foreach my $group (@groups) {

    #Add series label for legend
    $group_index++;
    $worksheet_groups->write_string($group_index, 0, $group);
    $worksheet_groups->write_number($group_index, 1, $group_index);

    #Add worksheet
    my $worksheet    = $workbook->add_worksheet("group_$group_index");

    #Add data to worksheet
    my @values       = sort {$a <=> $b} @{$series->{$group}->{'values'}};
    my $values_count = scalar(@values);
    $worksheet_groups->write_number($group_index, 2, $values_count);
    my @cdf          = ();
    my $loop         = 0;
    foreach my $value (@values) {
      $loop++;
      push @cdf, $loop/$values_count;
    }
    $worksheet->write_row(A1 => [$group, 'Probability'] );
    $worksheet->write_row(A2 => [\@values, \@cdf] );

    my $stat = {};
    $stat->{'min'}      = $values[0];
    $stat->{'max'}      = $values[-1];
    my $p50_group_index = first_index {$_ >= 0.5} @cdf;
    $stat->{'p50'}      = $values[$p50_group_index];
    my $p90_group_index = first_index {$_ >= 0.9} @cdf;
    $stat->{'p90'}      = $values[$p90_group_index];

    push @stats_groups, $stat;

    #Add data references to chart
    my $color = shift @colors || 'black';
    $chart->add_series(
        line       => {color => $color},
        name       => sprintf('=%s!$A$%s', 'groups', $group_index + 1), #groups header row is 0
        categories => sprintf('=%s!$A$2:$A$%s', $worksheet->get_name, $values_count + 1),
        values     => sprintf('=%s!$B$2:$B$%s', $worksheet->get_name, $values_count + 1),
    );

  } #foreach group

  my $maxset;
  if (@stats_groups) {
    require List::Util;
    require Math::Round::SignificantFigures;

    my $max      = List::Util::max(map {$_->{'max'}} @stats_groups);
    my $p50      = Math::Round::SignificantFigures::ceilsigfigs(List::Util::max(map {$_->{'p50'}} @stats_groups) * 1.5, 2);
    my $p90      = Math::Round::SignificantFigures::ceilsigfigs(List::Util::min(map {$_->{'p90'}} @stats_groups) * 1.5, 2);
    $maxset   = List::Util::max($p50, $p90);
    $maxset      = undef if $maxset > $max;
  }

  #Configure chart
  $chart->set_title( name => $self->chart_title                               );
  $chart->set_y_axis(name => $self->chart_y_label, min => 0   , max => 1      );
  $chart->set_x_axis(name => $self->chart_x_label,              max => $maxset);
  $chart->set_legend(none => 1) unless $self->chart_legend_display;

  #Write Excel output to filehandle
  $workbook->close;

  return $content;

}

=head2 generate_file

Returns Excel file name in temp folder

  use File::Copy qw{move};
  my $filename = $writer->generate_file(\@data);
  move $filename, '.';

=cut

sub generate_file {
  require DateTime;
  require File::Temp;

  my $self            = shift;
  my $ymd             = DateTime->now->ymd;
  my ($fh, $filename) = File::Temp::tempfile("excel-cdf-$ymd-XXXXXX", SUFFIX => '.xlsx', DIR => File::Temp::tempdir());
  binmode($fh);
  my $blob            = $self->generate(@_);
  print $fh $blob;
  close($fh);
  return $filename;
}

=head1 SEE ALSO

L<Excel::Writer::XLSX>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
