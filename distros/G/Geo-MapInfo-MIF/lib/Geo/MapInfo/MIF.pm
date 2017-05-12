package Geo::MapInfo::MIF;

use 5.006;
use strict;
use File::Slurp;
use Text::CSV;
use Params::Util  qw{_INSTANCE};
use File::Basename;

our $VERSION = '0.02';

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub trim($)	{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub read_files	{
	my $mif_file = "";
	my $mid_file = "";
	#check which file is which
	#fileparse("/foo/bar/baz.txt", qr/\.[^.]*/);
	my($filename, $directories, $suffix) = fileparse($_[0], qr/\.[^.]*/);
	if ($suffix =~ /mif/i)	{
		$mif_file = $_[0];
		if (-e $directories.$filename.".mid")	{
			$mid_file = $directories.$filename.".mid";
		}
		elsif (-e $directories.$filename.".MID")	{
			$mid_file = $directories.$filename.".MID";
		}
		else	{
			die "Cannot find the mid file.\n$filename\n$suffix\n$directories\n";
		}
	}
	else	{
		if (-e $directories.$filename.".mif")	{
			$mid_file = $directories.$filename.".mif";
		}
		elsif (-e $directories.$filename.".MIF")	{
			$mid_file = $directories.$filename.".MIF";
		}
		else	{
			die "Cannot find the mif file,\n";
		}
		$mid_file = $_[0];
	}
	
	my @mif_lines = File::Slurp::read_file($mif_file);
	my @mid_lines = File::Slurp::read_file($mid_file);

	my @answer = (\@mif_lines, \@mid_lines);
	
	return @answer;
}

sub read_mif_file	{
	my ($mif_file) = @_;
	
	my @mif_lines = File::Slurp::read_file($mif_file);
	
	return @mif_lines;
}


sub get_mif_info	{
	my %mif_info;
	my @mif_lines = @_;
	my $i=0;
	do	{
		if ($mif_lines[$i] =~ /(version)(\s+)(\d+)/gi)	{
			$mif_info{Version} = $3;
		}
		elsif ($mif_lines[$i] =~ /(charset)(\s+)(.+)/gi)	{
			$mif_info{Charset} = $3;
		}
		elsif ($mif_lines[$i] =~ /(delimiter)(\s+)(.+)/gi)	{
			$mif_info{Delimiter} = $3;
		}
		elsif ($mif_lines[$i] =~ /(unique)(\s+)(.+)/gi)	{
			$mif_info{Unique} = $3;
		}
		elsif ($mif_lines[$i] =~ /(coordsys)(\s+)(.+)/gi)	{
			$mif_info{Coordsys} = $3;
		}
		elsif ($mif_lines[$i] =~ /(transform)(\s+)(.+)/gi)	{
			$mif_info{Transform} = $3;
		}
		elsif ($mif_lines[$i] =~ /(columns)(\s+)(\d+)/gi)	{
			for (my $j = 1; $j <= $3; $j++)	{
				$mif_lines[$i+$j] =~ /\d*(\w+)\s+([a-zA-z_\(\)0-9]+)/g;
				$mif_info{Columns}[$j-1] = $1;
			}
		}
		$i++;
	} until ($mif_lines[$i] =~ m/data/gi);
	return %mif_info;
}

sub process_regions	{
	my $column = $_[0];
	my @mif_lines = @{$_[1]};
	my @mid_lines = @{$_[2]};
	my %regions;
	my $current_mid_row = 0;
	
	my $csv = Text::CSV->new();
	
	for (my $i = 0; $i < $#mif_lines; $i++)	{
		if ($mif_lines[$i] =~ /\s*region\s*(\d+)/i)	{
			my $mid_row = $csv->parse($mid_lines[$current_mid_row++]);
			my @mid_row_array = $csv->fields;
			my $no_regions = $1;
			for (my $k = 0; $k < $no_regions; $k++)	{
				my $no_rows = trim($mif_lines[++$i]);
				my @region = "";
				for (my $j = $i+1; $j < $i+1+$no_rows; $j++)	{
					my @temp = split(/\s+/, $mif_lines[$j]);
					$region[$j-$i-1] = \@temp;
				}
				$i = $i + $no_rows;
				push @{$regions{trim($mid_row_array[$column])}}, \@region;
			}
		}
	}
	return %regions;
}


1;

__END__

=pod

=head1 NAME

Geo::MapInfo::MIF - Perl extension for handling MapInfo Interchange Format (MIF) files.

=head1 SYNOPSIS

  use Geo::MapInfo::MIF;
  
  my @file_contents = Geo::MapInfo::read_files($mif_file);
  
  my %regions = Geo::MapInfo::MIF::process_regions($column, $file_contents[0], $file_contents[1]);
  
=head1 ABSTRACT

The Geo::MapInfo::MIF module reads a MapInfo Interchange Format (MIF) file and the associated MID file.  It uses the data found in this document http://www.directionsmag.com/mapinfo-l/mif/AppJ.pdf to parse the files.

=head1 DESCRIPTION

The Geo::MapInfo::MIF module reads a MapInfo Interchange Format (MIF) file and the associated MID file.  It uses the data found in this document http://www.directionsmag.com/mapinfo-l/mif/AppJ.pdf to parse the files.

=head1 METHODS

=item read_files($filename)

If given a MIF file it looks for the associated MID file.  If given a MID file it looks for the associated MIF file.  This only looks in the same directory as the given file and assumes that both files have the same basename.  Returns (\@mif_lines, \@mid_lines).

=item get_mif_info(@mif_lines)

This returns a hash containing the MIF file header.

=item process_regions($column, @mif_lines, @mid_lines)

Returns a hash of arrays of arrays in the following format:

%hash{region_name} = ([$long0, $lat0], [$long1, $lat1], [$long2, $lat2], ...)

$column is the index of the field of the column array returned by get_mif_info that contains the name of the region.

=head1 AUTHOR

Jeffery Candiloro E<lt>jeffery@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Jeffery Candiloro.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut