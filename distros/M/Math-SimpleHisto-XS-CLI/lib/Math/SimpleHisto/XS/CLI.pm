package Math::SimpleHisto::XS::CLI;
use 5.008001;
use strict;
use warnings;

our $VERSION = '1.07';

use constant BATCHSIZE => 1000;
use Carp 'croak';
use Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
  histogram_from_dumps_fh
  histogram_from_random_data
  histogram_from_fh
  histogram_slurp_from_fh
  minmax
  display_histogram_using_soot

  intuit_ascii_style
  intuit_output_size
  draw_ascii_histogram 
  print_hist_stats
);
our %EXPORT_TAGS = (
  'all' => \@EXPORT_OK,
);

use Math::SimpleHisto::XS;

sub histogram_from_dumps_fh {
  my ($fh) = @_;

  my $hist;
  my $tmphist;
  #require Math::SimpleHisto::XS::Named; # TODO implement & test using this
  while (my $dump = <$fh>) {
    next if not $dump =~ /\S/;
    foreach my $type (qw(json yaml simple)) {
      eval {$tmphist = Math::SimpleHisto::XS->new_from_dump($type, $dump);};
      last if defined $tmphist;
    }
    if (defined $tmphist) {
      if ($hist) { $hist->add_histogram($tmphist) }
      else { $hist = $tmphist }
    }
  }
  Carp::croak("Could not recreate histogram from input histogram dump string")
    if not defined $hist;

  return $hist;
}

sub histogram_from_random_data {
  my ($histopt, $random_samples) = @_;
  my %opt = %$histopt;
  $opt{min} ||= 0;
  $opt{max} ||= 1;
  $random_samples = 1000 if not $random_samples;

  my $hist = Math::SimpleHisto::XS->new(
    min   => $opt{min},
    max   => $opt{max},
    nbins => $opt{nbins},
  );

  my $min = $hist->min;
  my $width = $hist->width;
  $hist->fill($min + rand($width)) for 1..$random_samples;

  return $hist;
}

sub histogram_from_fh {
  my ($histopt, $fh, $hist) = @_;
  
  $hist ||= Math::SimpleHisto::XS->new(map {$_ => $histopt->{$_}} qw(nbins min max));

  my $pos_weight = $histopt->{xw};
  my (@coords, @weights);
  my $i = 0;

  my ($rbits);
  my $step_size = $histopt->{stepsize};
  if ($step_size) {
    $rbits = '';
    vec($rbits, fileno($fh), 1) = 1;
  }

  while (1) {
    if ($step_size) {
      my ($havedata, undef) = select($rbits, undef, undef, 0.1);
      if (not $havedata) {
        last if $i >= 1;
        redo;
      }
      $_ = <$fh>;
    }
    else {
      $_ = <$fh>;
    }
    last if not defined $_;
    chomp;
    my @row = split " ", $_;
    ++$i;
    if ($pos_weight) {
      push @{ ($i % 2) ? \@coords : \@weights }, $_ for split " ", $_;
    }
    else {
      push @coords, split " ", $_;
    }
    if (@coords >= BATCHSIZE) {
      my $tmp;
      $tmp = pop(@weights) if @coords != @weights;
      $hist->fill($pos_weight ? (\@coords, \@weights) : (\@coords));

      @coords = ();
      @weights = (defined($tmp) ? ($tmp) : ());
    }

    last if $step_size and $i >= $step_size;
  }

  $hist->fill($pos_weight ? (\@coords, \@weights) : (\@coords))
    if @coords;

  return $hist;
}

# modifies input options
sub histogram_slurp_from_fh {
  my ($histopt, $fh) = @_;

  my $pos_weight = $histopt->{xw};
  my $hist;
  my (@coords, @weights);
  my $i = 0;
  while (<STDIN>) {
    chomp;
    s/^\s+//; s/\s+$//;
    if ($pos_weight) {
      push @{ (++$i % 2) ? \@coords : \@weights }, $_ for split " ", $_;
    }
    else {
      push @coords, split " ", $_;
    }
  }

  # Without input and configured histogram boundaries, we can't make one
  # TODO: should this be silent "success" or an empty histogram (for dump
  #       output mode) or an exception?
  exit(0) if not @coords;
  my ($min, $max) = minmax(@coords);
  $histopt->{min} = $min if not defined $histopt->{min};
  $histopt->{max} = $max if not defined $histopt->{max};

  $hist = Math::SimpleHisto::XS->new(map {$_ => $histopt->{$_}} qw(nbins min max));
  $hist->fill($pos_weight ? (\@coords, \@weights) : (\@coords));

  return $hist;
}

sub minmax {
  my ($min, $max);
  for (@_) {
    $min = $_ if not defined $min or $min > $_;
    $max = $_ if not defined $max or $max < $_;
  }
  return($min, $max);
}

sub display_histogram_using_soot {
  my ($hist) = @_;
  my $h = $hist->to_soot;
  my $cv = TCanvas->new;
  $h->Draw();
  my $app = $SOOT::gApplication = $SOOT::gApplication; # silence warnings
  $app->Run();
  exit;
}


our %AsciiStyles = (
  '-' => {character => '-', end_character => '>'},
  '=' => {character => '=', end_character => '>'},
  '~' => {character => '~', end_character => '>'},
);

# Determine the style to use for drawing the histogram
sub intuit_ascii_style {
  my ($style_option) = @_;
  $style_option = '~' if not defined $style_option;
  if (not exists $AsciiStyles{$style_option}) {
    if (length($style_option) == 1) {
      $AsciiStyles{$style_option} = {character => $style_option, end_character => $style_option};
    }
    else {
      die "Invalid histogram style '$style_option'. Valid styles: '"
          . join("', '", keys %AsciiStyles), "' and any single character.\n";
    }
  }

  my $styledef = $AsciiStyles{$style_option};
  return $styledef;
}


sub intuit_output_size {
  my ($ofh) = @_;

  $ofh ||= \*STDOUT;
  # figure out output width
  my ($terminal_columns, $terminal_rows);
  if (-t $ofh) {
    ($terminal_columns, $terminal_rows) = Term::Size::chars($ofh);
  }
  else {
    $terminal_columns = 80;
    $terminal_rows = 10;
  }

  return ($terminal_columns, $terminal_rows);
}

sub print_hist_stats {
  my ($ofh, $hist, $histopt) = @_;
  
  my $v_total_width = $histopt->{width} || (intuit_output_size($ofh))[0] - 2;
  # Total: X Fills: X Mean: X Median: X
  my ($tot, $nfills, $mean, $median) = map $hist->$_, qw(total nfills mean median);
  my $str = sprintf("Total: %f NFills: %u Mean: %f Median %f\n", $tot, $nfills, $mean, $median);
  $str = substr($str, 0, $v_total_width);
  print $ofh $str;
}

# relevant options:
# - sort
# - width
# - min
# - max
# - numeric-format
# - show-numeric
# - timestamp
# - log
# - style
sub draw_ascii_histogram {
  my ($ofh, $rows, $histopt) = @_;

  my $convert_timestamps = $histopt->{timestamp};
  my $show_numeric = $histopt->{"show-numeric"};
  my $numeric_format = $histopt->{"numeric-format"};
  my $logscale = $histopt->{log};
  my $styledef = $histopt->{style};

  # extract min/max/width info from input data
  # The $v_ prefixed variables below refer to "visible" widths in columns.
  my $v_desc_width = 0;
  my $v_numeric_value_width  = 0;
  my $hist_total = 0;

  my ($hist_max, $hist_min);
  foreach my $row (@$rows) {
    my ($description, $value) = @$row;
    $row->[0] = $description = localtime(int($description)) if $convert_timestamps;

    my $formatted_value = sprintf($numeric_format, $value);

    $v_desc_width = length($description) if length($description) > $v_desc_width;
    $v_numeric_value_width  = length($formatted_value) if length($formatted_value) > $v_numeric_value_width;
    $hist_min = $value if !defined $hist_min or $value < $hist_min;
    $hist_max = $value if !defined $hist_max or $value > $hist_max;
    $hist_total += $value;
    # extend each row by the formatted numeric value -- just in case.
    push @$row, $show_numeric ? $formatted_value : '';
  }

  # sort by value if desired
  @$rows = sort {$a->[1] <=> $b->[1]} @$rows if $histopt->{sort};

  my $v_total_width = $histopt->{width} || (intuit_output_size($ofh))[0] - 2;

  if ($v_total_width < $v_desc_width + 3) {
    warn "Terminal or desired width is insufficient.\n";
    $v_total_width = $v_desc_width + 3;
  }

  $v_numeric_value_width = $show_numeric ? $v_numeric_value_width+2 : 0;
  # The total output width is comprised of the bin description, possibly
  # the width of the numeric bin content, and the width of the actual
  # histogram.
  my $v_hist_width = $v_total_width - $v_desc_width - $v_numeric_value_width - 3;

  # figure out the range of values in the visible part of the histogram
  my $min_display_value = $histopt->{min} || 0;
  if ($min_display_value =~ /^auto$/i) {
    $min_display_value = $hist_min;
  }
  $min_display_value = log($min_display_value||$hist_min*0.99||1e-9) if $logscale;

  my $max_display_value = $histopt->{max};
  if (not defined $max_display_value or $max_display_value =~ /^auto$/) {
    $max_display_value = $hist_max;
  }
  elsif ($max_display_value =~ /^total$/i) {
    $max_display_value = $hist_total;
  }
  $max_display_value = log($max_display_value) if $logscale;

  my $display_value_range = $max_display_value - $min_display_value;

  # format the output
  my $format = "%${v_desc_width}s: %${v_numeric_value_width}s|%-${v_hist_width}s|\n";
  my $hchar_body = $styledef->{character};
  my $hchar_end = $styledef->{end_character};
  my $hchar_end_len = length($hchar_end);

  # The actual output loop
  foreach my $row (@$rows) {
    my ($desc, $value, $formatted_value) = @$row;
    $value = log($value||1e-15) if $logscale;

    my $hlen = int(($value-$min_display_value) / $display_value_range * $v_hist_width);
    $hlen = 0 if $hlen < 0;
    $hlen = $v_hist_width if $hlen > $v_hist_width;

    if ($hlen >= $hchar_end_len) {
      printf($format, $desc, $formatted_value, ($hchar_body x ($hlen-$hchar_end_len)) . $hchar_end);
    }
    else {
      printf($format, $desc, $formatted_value, ($hchar_body x $hlen));
    }
  }

}


1;
__END__

=head1 NAME

Math::SimpleHisto::XS::CLI - Tools for the CLI tools

=head1 SYNOPSIS

  See the 'histify' and 'drawasciihist' CLI tools!

=head1 DESCRIPTION

This is a dummy module that simply serves as a way to make the
L<Math::SimpleHisto::XS>-related CLI tools installable separately
from the main module.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
