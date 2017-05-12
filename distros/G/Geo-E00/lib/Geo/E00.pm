# Geo::E00
# 
# Arc/Info Export (E00) parser.
#
#	Copyright (c) 2002-2003 Tower Technologies s.r.l.
#	All Rights Reserved
#       



package Geo::E00;

use strict;

use Carp;
use IO::File;

$Geo::E00::VERSION = '0.05';

# Constructor
sub new
{
	my ($proto) = @_;

	my $class = ref($proto) || $proto;

	return bless {
		'FH'	=> undef,
	}, $class;
}

sub open
{
	my ($self, $file) = @_;

	return undef unless defined $file;

	$self->{'FH'} = new IO::File $file, 'r';

	return $self->{'FH'};	
}

sub parse
{
	my ($self) = @_;
	my ($fn);

	my $fh = $self->{'FH'};

	return undef unless defined $fh;

	# Read the first line
	my $headline = $fh->getline;

	return undef unless defined $headline;

#	print STDERR $headline;

	return undef unless $headline =~ m|^EXP\s+(\d+)\s+(.+)\s*$|;

	$self->{'VERSION'} = $1;
	$self->{'EXPFILE'} = $2;

#	print STDERR "Version $self->{'VERSION'} , file $self->{'EXPFILE'}\n";

	my $data = {};

	while (my $line = $fh->getline)
	{
		if ($line =~ m|^([A-Z]{3})\s+(\d+)|)
		{
			# Section start

			my $section = $1;
			my $param = $2;

#			print STDERR "Got section: $section, $param\n";

			$data->{'arc'} = $self->parse_arc($fh, $param) if $section eq 'ARC';
			$data->{'cnt'} = $self->parse_cnt($fh, $param) if $section eq 'CNT';
			$data->{'lab'} = $self->parse_lab($fh, $param) if $section eq 'LAB';
			$data->{'tol'} = $self->parse_tol($fh, $param) if $section eq 'TOL';
			$data->{'tx7'} = $self->parse_tx7($fh, $param) if $section eq 'TX7';
			$data->{'log'} = $self->parse_log($fh, $param) if $section eq 'LOG';
			$data->{'prj'} = $self->parse_prj($fh, $param) if $section eq 'PRJ';
			$data->{'pal'} = $self->parse_pal($fh, $param) if $section eq 'PAL';
			$data->{'ifo'} = $self->parse_ifo($fh, $param) if $section eq 'IFO';
		}
	}
	$data = combine($data);

	return $data;
}

sub parse_arc
{
	my ($self, $fh) = @_;

	my @sets = ();

	while (my $line = $fh->getline)
	{
		# Check for termination pattern
		last if $line =~ m|^\s*-1(\s+0){6}|;

		# Set header
		if ($line =~ m|^\s*(\d+)\s+(\-?\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)|)
		{
			my $arc = {
				'cov-num'	=> $1,
				'cov-id'	=> $2,
				'node-from'	=> $3,
				'node-to'	=> $4,
				'poly-left'	=> $5,
				'poly-right'	=> $6,
				'npoints'	=> $7,
			};
			
			my @coords    = ();
			my @llcoords  = ();

#			print STDERR "NUM: $arc->{'cov-num'}, ID: $arc->{'cov-id'}, PAIRS: $arc->{'npoints'}\n"; 

			for (my $i = 0; $i < $arc->{'npoints'};)
			{
				# Get a new line

				my $cline = $fh->getline;

				# Check if this is a 2 pairs line

				if ($cline =~ m{^(\s*[ -]\d+\.\d+E[+-]\d+)(\s*[ -]\d+\.\d+E[+-]\d+)(\s*[ -]\d+\.\d+E[+-]\d+)(\s*[ -]\d+\.\d+E[+|-]\d+)})
				{
					$llcoords[$i]->{'x'}=$1;
					$llcoords[$i]->{'y'}=$2;
					$llcoords[$i+1]->{'x'}=$3;
					$llcoords[$i+1]->{'y'}=$4;
					
					push(@coords, $1, $2, $3, $4);

#					print STDERR " got 2 pairs line\n";
					$i += 2;

					next;
				}

				# 1 pair line

				if ($cline =~ m{^(\s*[ -]\d+\.\d+E[+-]\d+)(\s*[ -]\d+\.\d+E[+-]\d+)})
				{
					$llcoords[$i]->{'x'}=$1;
					$llcoords[$i]->{'y'}=$2;
					push(@coords, $1, $2);

#					print STDERR " got 1 pair line\n";
					$i += 1;

					next;
				}

				Carp::croak "Unknown pair line: $cline\n";
			}

			Carp::croak "Wrong number of x-y pairs in ARC <> $arc->{'npoints'}\n"
				 unless ((scalar @coords) / 2 ) eq $arc->{'npoints'};

			$arc->{'points'}   = \@coords;
			$arc->{'coord'}    = \@llcoords;

			push(@sets, $arc);

			next;
		}
	
		Carp::croak "Unknown set line: $line";	
	}
		
#	print STDERR Data::Dumper->Dump( [ \@sets ] );

#	print STDERR "END ARC SECTION\n";

	return \@sets;
}

sub parse_cnt
{
	my ($self, $fh) = @_;

	my @sets = ();

	while (my $line = $fh->getline)
	{
		# Check for termination pattern
		if ($line =~ m{^\s*(\d+)})
		{
			my $cnt = {
				'cnt-id'	=> $1,
			};
			$line = $fh->getline;
			last if $line =~ m|^\s*-1(\s+0){6}|;
			if ($line =~ m{^\s*(\d+)(\s*[ -]\d+\.\d+E[+-]\d+)(\s*[ -]\d+\.\d+E[+-]\d+)}) 
			{
				$cnt->{ 'x' } = $2;
				$cnt->{ 'y' } = $3;
			} else {
				Carp::croak "Unknown CNT line: $line\n";
			}
			
			# Store
			push(@sets, $cnt);
		}

	}
		
	return \@sets;
	
}


sub parse_lab
{
	my ($self, $fh) = @_;

	my @sets = ();

	while (my $line = $fh->getline)
	{
		# Check for termination pattern
		last if $line =~ m|^\s*-1\s+0|;

		# Set header
		if ($line =~ m{^\s*(\d+)\s+(\d+)(\s*[ -]\d+\.\d+E[+-]\d+)(\s*[ -]\d+\.\d+E[+-]\d+)})
		{
			my $lab = {
				'cov-id'	=> $1,
				'poly-id'	=> $2,
				'x'		=> $3,
				'y'		=> $4,
			};
			
			# Read and throw away the next line
			$fh->getline;

			# Store
			push(@sets, $lab);

			# Next set...
			next;
		}
	
		Carp::croak "Unknown set line: $line";	
	}
		
	return \@sets;
}

sub parse_tol
{
#	print STDERR "END TOL SECTION\n";
}

sub parse_tx7
{
#	print STDERR "END TX7 SECTION\n";
}

sub parse_log
{
	my ($self, $fh) = @_;

	my @sets = ();

	while (my $line = $fh->getline)
	{
		last if $line =~ m|^EOL|;
		
		my ($year,$month,$day,$hour,$minute,$connecttime,$cputime,$iotime,$commandline)=unpack(
			"a4 a2 a2 a2 a2 a4 a6 a6 a*",$line);
		my $log = {
			'year'		=> $year,
			'month'		=> $month,
			'day'		=> $day,
			'hour'		=> $hour,
			'minute'	=> $minute,
			'connecttime'	=> $connecttime,
			'cputime'	=> $cputime,
			'iotime'	=> $iotime,
			'commandline'	=> $commandline,
		};

		# Read and throw away the next line

		$fh->getline;
		push(@sets, $log);
	}
	return \@sets;
}

sub parse_prj
{
# 	not needed
#	print STDERR "END PRJ SECTION\n";
}

sub parse_ifo
{
	my ($self, $fh, $param) = @_;

	my $data;

	while (my $line = $fh->getline)
	{
		# Check for termination pattern
		last if $line =~ m|^EOI|;
		if ($line =~ m|^(.*)?\.([A-Z]{3})\s+XX\s+(\d+)\s+\d+\s+\d+\s+(\d+)|)
		{
			my $ifo = {
				section => $1,
				name => $2,
				items => $3,
				records => $4,
				lines => 1,
			};

			my $totallength = 0;

			for (my $i = 0; $i <$ifo->{items}; $i++) {
				my ($itemname,$widthpos,$startpos,$outputformat,$dummy) = 
					split(" ",$fh->getline,6);
				$widthpos        =~ s/-1$//;
				$startpos        =~ s/4-1$//;
				$outputformat    =~ s/-1$//;
				if ($outputformat == 12 ) { $outputformat = 14; }
				if ($outputformat ==  5 ) { $outputformat = 11; }

				$totallength    += $outputformat;
				$ifo->{format}  .= "a$outputformat ";
				if ($totallength > 80) {
					$ifo->{lines}++;	
					$totallength -= 80;
				}
				push @{$ifo->{item}},$itemname;
			}
			$data->{$ifo->{name}} = $self->parse_types($fh, $ifo);
		}

	}
	$data;
}


sub parse_pal
{
	my ($self, $fh) = @_;

	my @sets = ();

	while (my $line = $fh->getline)
	{
		# Check for termination pattern
		last if $line =~ m|^\s*-1(\s+0){6}|;

		# Set header
		if ($line =~ m{^\s*(\d+)(\s*[ -]\d+\.\d+E[+-]\d+)(\s*[ -]\d+\.\d+E[+-]\d+)(\s*[ -]\d+\.\d+E[+-]\d+)(\s*[ -]\d+\.\d+E[+|-]\d+)})
		{
			my $pal = {
				'npoints'	=> $1,
				'xmin'		=> $2,
				'ymin'		=> $3,
				'xmax'		=> $4,
				'ymax'		=> $5,
			};
			
			my @points = ();

			for (my $i = 0; $i < $pal->{'npoints'};)
			{
				# Get a new line

				my $cline = $fh->getline;

				# Check if this is a 2 pairs line

				if ($cline =~ m{^(\s*[ -]\d+)(\s*[ -]\d+)(\s*[ -]\d+)(\s*[ -]\d+)(\s*[ -]\d+)(\s*[ -]\d+)})
				{
					$points[$i]->{'arc-number'}  = $1;
					$points[$i]->{'node-number'} = $2;
					$points[$i]->{'polygon-number'} = $3;
					$points[$i+1]->{'arc-number'}  = $4;
					$points[$i+1]->{'node-number'} = $5;
					$points[$i+1]->{'polygon-number'} = $6;

#					print STDERR " got 2 pairs line\n";
					$i += 2;

					next;
				}

				# 1 pair line

				if ($cline =~ m{^(\s*[ -]\d+)(\s*[ -]\d+)(\s*[ -]\d+)})
				{
					$points[$i]->{'arc-number'}  = $1;
					$points[$i]->{'node-number'} = $2;
					$points[$i]->{'polygon-number'} = $3;

#					print STDERR " got 1 pair line\n";
					$i += 1;

					next;
				}

				Carp::croak "Unknown pair line: $cline\n";
			}

			Carp::croak "Wrong number of x-y pairs in PAL <> $pal->{'npoints'}\n"
				 unless ((scalar @points) ) eq $pal->{'npoints'};

			$pal->{'points'} = \@points;

			push(@sets, $pal);

			next;
		}
	
		Carp::croak "Unknown set line: $line";	
	}
		
	return \@sets;
}

sub parse_types
{
	my ($self, $fh, $ifo) = @_;

	my @sets = ();

	for (my $i = 0; $i < $ifo->{'records'}; $i++) {
		my ($types,@ri,$itemsnow);
		$itemsnow = 0;
		while ($itemsnow < $ifo->{'items'}) {	
			my ($line,$j,$x);
			for ($j =0; $j < $ifo->{'lines'}; $j++) {
				$x     = $fh->getline();chomp($x);
				$line .= sprintf("%-80s",$x)
			}
			my (@ri) = unpack($ifo->{format},$line);
			for ($j=0; $j < (@ri); $j++) {
				$ri[$j] =~ s/^ *//;$ri[$j] =~ s/ *$//;
				$types->{$ifo->{'item'}->[$j+$itemsnow]}=$ri[$j];
			}
			$itemsnow += (@ri);
		}
		push(@sets, $types);
	}
	$ifo->{data}=\@sets;
	return $ifo;
}

sub combine
{
	my ($data) = @_;
	my ($rarc, $rlab);

	if (defined($data->{'arc'})) {
		my $nr  = 0;
		my $arc = $data->{arc};
                foreach my $arcline (@$arc) {
			$rarc->{$arcline->{"cov-num"}} = $nr++;
		}
	}

	if (defined($data->{'lab'})) {
		my $nr  = 0;
		my $lab = $data->{lab};
                foreach my $labline (@$lab) {
			$rlab->{$labline->{'poly-id'}} = $nr++;
		}
	}

	if (defined($data->{'ifo'})) {
#___________________________________________________
# AAT Part
#___________________________________________________
		if (defined($data->{'ifo'}->{'AAT'})) {	
			my $aat = $data->{'ifo'}->{'AAT'};
			my (@el,$item,$nr);
		# the next AAT field will be saved in the ARC structure
		# 0 FNODE#            
		# 1 TNODE#           
		# 2 LPOLY#          
		# 3 RPOLY#         
		# 4 LENGTH        saved
		# 5 RRLINE#       < compare with cov_num
		# 6 RRLINE-ID   
		# 7 ..		extra fields
			$nr=0;
			foreach $item (@{$aat->{item}}) { 
				$el[$nr++] = $item;
			}
			my $dline;	
			foreach $dline (@{$aat->{data}}) { 
				$nr = $rarc->{$dline->{$el[5]}};
				$data->{'arc'}->[$nr]->{$el[4]} =  $dline->{$el[4]};
				for (my $i = 7; $i <$aat->{items}; $i++) {
					$data->{'arc'}->[$nr]->{$el[$i]} =  $dline->{$el[$i]};
				}
			}
			
		}
#___________________________________________________
# PAT Part
#___________________________________________________
		if (defined($data->{'ifo'}->{'PAT'})) {
			my $pat = $data->{'ifo'}->{'PAT'};
			my (@el,$item,$nr);
		# the next PAT field will be saved in the LAB structure
		# 0 AREA             
		# 1 PERIMETER       
		# 2 PPPOINT#       
		# 3 PPPOINT-ID    
		# 4 ..
			$nr=0;
			foreach $item (@{$pat->{item}}) { 
				$el[$nr++] = $item;
			}
			my $dline;	
			foreach $dline (@{$pat->{data}}) { 

				$nr = $rlab->{$dline->{$el[2]}};
				for (my $i = 4; $i <$pat->{items}; $i++) {
					$data->{'lab'}->[$nr]->{$el[$i]} =  $dline->{$el[$i]};
				}
			}
		}
	}
	$data;
}

1;

__END__

=head1 NAME

Geo::E00 - Perl extension for reading Esri-E00 formats

=head1 SYNOPSIS


  use Geo::E00;

  $e00 = new Geo::E00;

  $e00->open($file);

  $e00data = $e00->parse();

  $arcdata = $e00data->{arc};

  print "Arcpoint";
  foreach $arc (@$arcdata) {
	print $arc->{npoints},"\n";
  }

=head1 STRUCTURES

=over 4

=item	ARC

			$arc = {
				'cov-num'	=> SCALAR,
				'cov-id'	=> SCALAR,
				'node-from'	=> SCALAR,
				'node-to'	=> SCALAR,
				'poly-left'	=> SCALAR,
				'poly-right'	=> SCALAR,
				'npoints'	=> SCALAR,
				'points'	=> ARRAY,
				'LENGTH'	=> SCALAR,	<- From AAT
				....		=> SCALAR,	<- From AAT
			# containing x,y pairs
				'coord'	=> ARRAY,
			# pointing to 
					->{x} and ->{y}
			};

=item	CNT

			my $cnt = {
				'cnt-id'	=> SCALAR,
				'x'		=> SCALAR,
				'y'		=> SCALAR,
			}

=item	LAB

			my $lab = {
				'cov-id'	=> SCALAR,
				'poly-id'	=> SCALAR,
				'x'		=> SCALAR,
				'y'		=> SCALAR,
			};

=item	LOG

		 $log = {
			'year'		=> SCALAR,
			'month'		=> SCALAR,
			'day'		=> SCALAR,
			'hour'		=> SCALAR,
			'minute'	=> SCALAR,
			'connecttime'	=> SCALAR,
			'cputime'	=> SCALAR,
			'iotime'	=> SCALAR,
			'commandline'	=> SCALAR,
		};

=item	PAL

			my $pal = {
				'npoints'	=> SCALAR,
				'xmin'		=> SCALAR,
				'ymin'		=> SCALAR,
				'xmax'		=> SCALAR,
				'ymax'		=> SCALAR,
				'points'	=> ARRAY,
				# pointing to 
					{'arc-number'}  = SCALAR;
					{'node-number'} = SCALAR;
					{'polygon-number'} = SCALAR;
			};

=back

=head1 DESCRIPTION

Hereafter follows an

=head1 INTRODUCTION


Note:  ESRI considers the export/import file format to be proprietary.  As a consequence, the identified format can only constitute a "best guess" and must always be considered as tentative and subject to revision, as more is learned.

It appears that all ARC/INFO files except user-created lookup tables are exported, including .ACODE and .PCODE.
=head1 OVERALL ORGANIZATION

The export file begins with a line with three fields.

	1-	an initial 'EXP'
	2-	what appears to be a constant of '0'
	3-	the pathname for the creation of the export file

The export file ends with a line beginning 'EOS'.

The ARC files are included first, in alphabetical order except for the SIN, LOG, and PRJ files which occur last.  Then the INFO files are included in alphabetical order.

The beginning of each ARC file is indicated by the file name (a three-character identifier) followed by '  2' for single-precision or '  3' for double-precision.  Single-precision carries 8 digits, and double-precision carries 15 digits.

Each ARC file ends with a line of seven numbers beginning with a -1 and followed by six zeros, except the SIN, LOG, and PRJ files which end in 'EOX', 'EOL', and 'EOP', respectively.  The LAB file uses a slight variation of this -1 ending line (see below).  The format for each ARC file is specific to that type of file.  These formats are covered below.

The beginning of the INFO file section is indicated by 'IFO  2', and its end is indicated by 'EOI'. The INFO files each begin with the file name.  For example, the polygon attribute table would be 'STDFIG24C.PAT' on a line by itself.  The format is the same for every INFO file.  This format is given below.
=head1 ARC FILE FORMATS

Formats will be given for the most common ARC files:

	-	ARC
	-	CNT
	-	LAB
	-	LOG
	-	PAL
	-	PAR
	-	PRJ
	-	SIN
	-	TOL

=head2 1	ARC

The ARC (arc coordinates and topology) file consists of repeating sets of arc information.  The first line of each set has seven numbers:

	1.	coverage#
	2.	coverage-ID
	3.	from node
	4.	to node
	5.	left polygon
	6.	right polygon
	7.	number of coordinates

The subsequent lines of a set are the coordinates with two x-y pairs per line, if the coverage is single-precision.  If there are an odd number of coordinates, the last line will have only one x-y pair.  Double-precision puts one coordinate pair on each line.

=head2 2	CNT

The CNT (Polygon Centroid Coordinates) file contains the centroid of each polygon in the coverage.  It has sets of centroid information with an initial coordinate line and, if there are labels, one line per label giving the number for the label.  The coordinate line has three fields:

	1-	number of labels in polygon
	2-	centroid x
	3-	centroid y

=head2 3	LAB

The LAB (label point coordinates and topology) file consists of repeating sets of label point information.  The first line of each set has four numbers:

	1.	coverage-ID
	2.	polygon which encloses it
	3.	x coordinate
	4.	y coordinate

The second and final line of the set gives the label box window. This information is marked as marked as obsolete in the SDL documentation.  It currently contains repetitions of the x and y coordinates.


=head2 4	LOG

The LOG (Coverage History) file contains a free form set of lines of indeterminate number which are separated by lines which begins with a tilde, "~".

ARC records many commands and their resource impacts in this file.  The standard ARC format for writing in the LOG has nine fields:

	-	Year (I4)
	-	Month (I2)
	-	Day (I2)
	-	Hours (I2)
	-	Minutes (I2)
	-	Connect Time in minutes (I4)
	-	CPU Time in seconds (I6)
	-	I/O Time in seconds (I6)
	-	Command line (A100)

However, any information can be added to the LOG file in free-form format.

=head2 	5	PAL

The PAL (Polygon Topology) file consists of repeating sets of polygon information.  The first line of each set has five numbers:

	1.	number of arcs in polygon
	2.	x min of polygon
	3.	y min of polygon
	4.	x max of polygon
	5.	y max of polygon

The subsequent lines of a set give information on the arcs which comprise the polygon.  There are three numbers per arc with information for two arcs per line.

	1.	the arc number (negative if reversed)
	2.	the node number
	3.	the polygon number

The first polygon given is the universal polygon.

"The PAL file contains the polygon topology for a coverage and min-max boxes for the polygons.  For each polygon in a coverage the PAL file has a (usually) clockwise list of the arcs, nodes that comprise the polygons, as well as the adjacent polygons, and a min-max box.  To keep a continuous list, 'virtual' arcs with arc# of 0 are used to connect to holes (thus forming donuts), which are connected in counter-clockwise order.  The PAL file is a random access, variable record length file, with the length dependent on the number of arcs surrounding the polygon (1 to 10000).

The arc# in the PAL file is the record number of that arc within the coverage's ARC file, the node# is the same as the node# in the arc file at the appropriate end, and the polygon# is the record number of that polygon within the coverage's PAL file. The PAL file record number for a polygon is the same as the PAT file record number and the CNT file record number."  SDL documentation, July 1989, p. 24.

=head2 6	PRJ

The PRJ (Projection Parameters) file consists of a set of projection keywords and values including a set of parameters following the keyword "Parameters".

This file needs further research for specific keywords and parameters for the projections supported by ADS and MOSS.

=head2 7 	SIN

Spacial Index

It usually is comprised of a single line with the value "EOX".


=head2 8	TOL

This consists of ten lines with a tolerance type, a tolerance status, and a tolerance value on each line.  The tolerance types are:

	1.	fuzzy
	2.	generalize (unused)
	3.	node match (unused)
	4.	dangle
	5.	tic match
	6.	undefined
	7.	undefined
	8.	undefined
	9.	undefined
	10.	undefined

The tolerance status "is set to 1 if the tolerance is verified (been applied to operations of the coverage) and to 2 if the tolerance is not verified (been set by the TOLERANCE command, but not yet used in processing)."  

=head2 	INFO FILE FORMATS

INFO files follow the same format:

	-	name of the info file and summary information
	-	definitions for each of the items
	-	actual data values

The name line consists of six fields:

	1.	name of the INFO file
	2.	appears to be flag for ARC/INFO table ('XX') or other INFO table ('  ')
	3.	number of items
	4.	appears to repeat number of items 
	5.	length of data record
	6.	number of data records

The definitions for each item consist of eight fields:

	1-	name of item
	2-	width of item followed by a constant of '-1'
	3-	start position of item followed by a constant of '4-1'
	4-	output format of item (see below for discussion)
	5-	type of item (see below for discussion)
	6-	appears to be constant of '-1'
	7-	appears to be constant of '-1-1'
	8-	appears to be sequential identifier

The output format field is handled differently for numeric and character items.  Numeric items give the output width followed by a space then the number of decimal positions.  Character items give the output width followed by a constant of '-1'.

The type of the item is specified by the following codes:

	-	20-1 indicates character
	-	50-1 indicates binary integer
	-	60-1 indicates real number

The other item types have not yet been identified.

Formats will be given for the most common INFO files:

	-	.AAT
	-	.ACODE
	-	.BND
	-	.PAT
	-	.PCODE
	-	.TIC

=head2	.AAT

The .AAT (Arc Attribute Table) contains seven fields whose item names are self-explanatory.  However, additional items may be added as desired, after the -ID item.

=head2 .ACODE

The .ACODE (Arc Lookup Table) contains seven fields whose item names are the same (except the -ID) as that in the ADS files documentation.  However, additional items should be able to be be added as desired, after the LABEL item.

=head2	.BND

The .BND (Coverage Min/Max Coordinates) table contains four fields whose item names are self-explanatory.

=head2 .PAT

The .PAT (Polygon or Point Attribute Table) contains four fields whose item names are self-explanatory.  However, additional items may be added as desired, after the -ID item.

=head2	.PCODE

The .PCODE (Polygon Lookup Table) contains eight fields whose item names are the same (except the -ID) as that in the ADS files documentation.  However, additional items should be able to be be added as desired, after the LABEL item.

=head2	.TIC

The .TIC (Tic Coordinates) table contains three fields whose item names are self-explanatory.


=head1	CONCLUSION

The content and format of the ARC EXPORT file seems to be straightforward in most cases.  The remaining areas of uncertainty include:

	-	confirmation of the meaning of the second field in the identification line for INFO files ('XX' or '  ')

	-	the meaning of the 'SIN 2' section

	-	the precise format of the PRJ file for different projections

	-	possible variation in the '-1' suffixes of INFO definitions

	-	INFO codes for item types other than character, integer, and real.

However, none of these appears to be that serious, and the indicated formats should be used to identify any errors or limitations.

Because this information was derived from limited experimentation, it should be considered as tentative and subject to revision at any time.

=head1 CAUTION

Note:  ESRI considers the export/import file format to be proprietary.  As a consequence, the identified format can only constitute a "best guess" and must always be considered as tentative and subject to revision, as more is learned.

=head1 EXAMPLES

   use Geo::E00;

   $file = shift;

   $io = new Geo::E00;

   $io->open($file);

   $e00data = $io->parse();
   $arcdata = $e00data->{arc};
   $cntdata = $e00data->{cnt};

   print "Arcpoint";
   foreach $arc (@$arcdata) {
	print $arc->{npoints},"\n";
	print $arc->{LENGTH},"\n";
   }

   print "Arcpoint longitude (x) - latitude (y)";
   foreach $arc (@$arcdata) {
	foreach $ll (@{$arc->{coord}}) {
		print "Longitude $ll->{x}\n";
		print "Latitude  $ll->{y}\n";
	}
   }

=head1 TODO

Suggestions are welcome. ;)

=head1 HISTORY

=over

=item 0.01 2002/10/24 initial release.

=item 0.02 2002/10/30 Added support for LAB section

=item 0.03 2003/05/01 Added support for PAL, IFO, PRJ, log section, + documentation

=item 0.04 2003/05/24 Bugs removed for negative x-y pairs and PAL section

=item 0.05 2003/05/25 Some minor style changes and fixes

=back

=head1 AUTHORS

 Alessandro Zummo <azummo dash e00perl at towertech dot it>
 Bert Tijhuis <B dot Tijhuis at inter dot nl dot net>

=head1 SEE ALSO

 Geo::E00 is released under the GPL end its development
 is funded by Tower Technologies (http://www.towertech.it). 

=head1 COPYRIGHT AND LICENCE


 Copyright (C) 2002-2003 Tower Technologies s.r.l. 
 Copyright (C) 2002-2003 Alessandro Zummo
 Copyright (C) 2003 Bert Tijhuis

 This package is free software and is provided "as is"
 without express or implied warranty. It may be used, modified,
 and redistributed under the same terms as Perl itself.

=cut
