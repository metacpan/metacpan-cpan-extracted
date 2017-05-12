#!/usr/bin/perl -X
package Finance::Quant::Charter;

use strict;
use warnings;
use Data::Dumper;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Finance::Quant::Charter ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
html diffcheck
);

our $VERSION = '0.01';

# Preloaded methods go here.


  use MIME::Base64;
  use  Finance::Quant::TA;
  use GD::Graph::lines;
  use Finance::Quant;
	# my @headers = qw/ Date Open High Low Close Volume /; hardcoded in _tbl()
	# $q->{Close} assumed exists in plotlog() & plotdiff()
	sub html {
		my ($stock, $q, $ma, $diff) = @_;
		print "generating html...\n";
		
		my $quant = Finance::Quant->new;
		
		
        my   $image =  $quant->get_source_image(sprintf("http://content.nasdaq.com/ibes/%s_Smallcon.jpg",$stock));        

        
		my $xguru = "";
	    my $ff = "";
        
        if($image!~/DQoNCjwhRE9DVFlQRSBodG1sIFBVQkxJQyAiLS8vVzNDLy9EVEQgWEhUTUwgMS4wIFRyYW5zaXRp/)   {        
         $ff = $quant->get_source_image(sprintf("http://community.nasdaq.com/community-ratings.aspx?stockticker=%s&AllRatings=1",$stock));
         
        if($ff =~ /<b>(.*)ratings<\/b>/){
          $quant->{'result'}=$1;
        }
        }
         
         	my @guru = $quant->getguruscreener($stock);
		
		 $xguru ="<pre><ul>";
		 
		 $xguru ="<li>nasdaq comunity rating:".$quant->{result}."</li>" unless(!$quant->{result});
	
		foreach my $gu (@guru){
		
		    $xguru .= sprintf("<li>raiting:[%s]\t\t%s</li>",$gu->{pct},$gu->{methode});
		
		}
		$xguru .="</ul></pre>";
		
		my $str = "";
		$str .= "<html><head><title>$stock</title></head><body bgcolor=\"#00000\" text=\"ffffff\"><div style='float:left'>".$xguru."</div><div style='float:right;'><center>\n";
		
		$str .= "<p><img src=\"data:image/png;base64," . encode_base64($image) . "\"></p>\n" unless(!defined($image)  || !defined($quant->{'result'}));
		$str .= "<p><img src=\"data:image/png;base64," . plotlog($stock, $q, $ma) . "\"></p>\n";
		$str .= "<p><img src=\"data:image/png;base64," . plotdiff($stock, $q, $ma, $diff) . "\"></p>\n";
		$str .=  _tbl($stock, $q);
		$str .= "</center></div></body></html>\n";
		return $str;
	}
	
	sub plotlog {
		my ($stock, $q, $diff) = @_;
		my $img = $stock . "log.jpg";
		print "generating $img...\n";
		my ($s, $lines) = ([],[]);
		my $y_format = sub { sprintf " \$%.2f", exp $_[0] };
		
		$s = Finance::Quant::TA::logs($q->{Close});
		$lines->[0] = {	name => 'Log of Closing Price', color => 'marine', data => $s };
		$lines->[1] = {	name => "MA($diff) (Moving Avg)", color => 'cyan', data => Finance::Quant::TA::ma($lines->[0]->{data}, $diff) };


        my $xdata = undef;
		
		$xdata = plotlines($img, $stock, $q->{Date}, $lines, $y_format);
		
		return $xdata;
	}

	sub plotdiff {
		my ($stock, $q, $lag, $diff) = @_;
		my $img = $stock . "diff.jpg";
		print "generating $img...\n";
		my ($s, $lines) = ([],[]);
		my $y_format = sub { sprintf "  %.2f", $_[0] };

		$s = Finance::Quant::TA::logs($q->{Close});
		
		my $diffx = Finance::Quant::TA::diff($s, $diff); 
		
		
		$lines->[0] = {	name => "Diff($diff)", color => 'marine', data => $diffx };
		$lines->[1] = {	name => "MA($lag) (Moving Avg)", color => 'cyan', data => Finance::Quant::TA::ma($lines->[0]->{data}, $lag) };
		$s = Finance::Quant::TA::stdev($lines->[0]->{data}, $lag);
		$s = Finance::Quant::TA::nstdev_ma($s, $lines->[1]->{data}, 2);
		$lines->[2] = {	name => 'MA + 2 Std Dev', color => 'lred', data => $s->[0] };
		$lines->[3] = {	name => 'MA - 2 Std Dev', color => 'lred', data => $s->[1] };
		
		
		my(@ty,@tx);
		@ty =  @{$lines->[0]->{data}};
		
		@tx = @{$s->[1]};

        my $xdata = undef;		
         $xdata = plotlines($img, $stock, $q->{Date}, $lines, $y_format);		
		
		
		
		
		
		return $xdata;
	}
	
		sub diffcheck {
		my ($stock, $q, $lag, $diff) = @_;
		my $img = $stock . "diff.jpg";
		print "generating $img...\n";
		my ($s, $lines) = ([],[]);
		my $y_format = sub { sprintf "  %.2f", $_[0] };

		$s = Finance::Quant::TA::logs($q->{Close});
		
		my $diffx = Finance::Quant::TA::diff($s, $diff); 
		
		
		$lines->[0] = {	name => "Diff($diff)", color => 'marine', data => $diffx };
		$lines->[1] = {	name => "MA($lag) (Moving Avg)", color => 'cyan', data => Finance::Quant::TA::ma($lines->[0]->{data}, $lag) };
		$s = Finance::Quant::TA::stdev($lines->[0]->{data}, $lag);
		$s = Finance::Quant::TA::nstdev_ma($s, $lines->[1]->{data}, 2);
		$lines->[2] = {	name => 'MA + 2 Std Dev', color => 'lred', data => $s->[0] };
		$lines->[3] = {	name => 'MA - 2 Std Dev', color => 'lred', data => $s->[1] };
		
		
		my(@ty,@tx);
		@ty =  @{$lines->[0]->{data}};
		
		@tx = @{$s->[1]};
		
		if($ty[$#ty] < $tx[$#tx]) {
            return 1;
		}else{
		    return 0;
		}
	}
	
	sub plotlines {
		my ($file, $stock, $x, $lines, $y_format) = @_;
		my @legend;
		my ($data, $colors) = ([], []);
		
		$data->[0] = $x;   # x-axis labels
	
		for (0..$#{$lines}) {
			$data->[(1+$_)] = $lines->[$_]->{data};
			$colors->[$_] = $lines->[$_]->{color};
			$legend[$_] = $lines->[$_]->{name};
		}
	
		my $graph = GD::Graph::lines->new(1024,420);
		$graph->set (dclrs => $colors) or die $graph->error;
		$graph->set_legend(@legend) or die $graph->error;
		$graph->set (legend_placement => 'BC') or die $graph->error;
		$graph->set(y_number_format => $y_format) if $y_format;
		
		my $skipp = int(0.2*scalar(@{$data->[0]})) unless(!$data->[0]);
		
		$skipp = 0 unless($skipp);
		
		$graph->set (
			title => "stock: $stock",
			boxclr => 'black',
			bgclr => 'dgray',
			axislabelclr => 'white',
			legendclr => 'white',
			textclr => 'white',
			r_margin => 20,
			tick_length => -4,
			y_long_ticks => 1,
			axis_space => 10,
			x_labels_vertical => 1,
			x_label_skip => $skipp
		) or return;# die $graph->error;
		my $gd = $graph->plot($data) or return;# die $graph->error;
	
		#open (IMG, ">$file") or die $!;
		#binmode IMG;
		#print IMG 
		return encode_base64($gd->png());
	
	}
	
	sub _tbl {
		my ($stock, $q) = @_;
		my $str = "";
		my @headers = qw/ Date Open High Low Close Volume /;
		my $tr_start = "<tr align=\"center\">\n";
		$str .= "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";
		$str .= $tr_start . "<td colspan=\"" . scalar @headers . "\">";
		$str .= "<b>Stock: $stock</b></td></tr>\n";
		$str .= $tr_start;
		$str .= "<td><b>" . $headers[$_] . "</b></td>\n" for 0..$#headers;
		$str .= "</tr>\n";
		for my $i (reverse 0..$#{$q->{Date}}) {
			$str .= $tr_start;
			$str .= "<td>" . $q->{$headers[$_]}->[$i] . "</td>\n" for 0..$#headers;
			$str .= "</tr>\n";
		}
		$str .= "</table>\n";
		return $str;
	}	




1;
__END__
