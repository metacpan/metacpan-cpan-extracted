package Microarray::GEO::SOFT::GPL;

# parse the GPL part in GSE file
# or the GPL file itself

use List::Vectorize qw(!table);
use Carp;
use strict;

use base "Microarray::GEO::SOFT";

1;

sub new {

	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = { "file" => "",
	             "verbose" => 1,
	             @_ };
	bless($self, $class);

	return $self;
	
}

sub parse {

	my $self = shift;
	
	my $fh;
	if(! List::Vectorize::is_glob_ref($self->{file})) {
	
		open F, $self->{file} or croak "cannot open $self->{file}.\n";
		$fh = \*F;
	}
	else {
		$fh = $self->{file};
	}
	
	$self->_parse_platform($fh);
	
	return 1;
}

sub _parse_platform {

	my $self = shift;

	my $fh = shift;
	
	Microarray::GEO::SOFT::_set_fh($self->{verbose});
	
	my $accession;
	my $title;
	my $table_colnames = [];
	my $table_rownames = [];
	my $table_matrix = [];
	
	while(my $line = <$fh>) {
		
		chomp $line;
		if($line =~/^!Platform_geo_accession = (GPL\d+)$/
		   or $line =~/^!Annotation_platform = (GPL\d+)/) {
			$accession = $1;
		}
		
		if($line =~/^!Platform_title = (.*?)$/
		   or $line =~/^!Annotation_platform_title = (.*?)$/) {
			$title = $1;
		}

		if($line =~/^!platform_table_begin$/) {
			
			$line = <$fh>;
			chomp $line;
			
			@$table_colnames = split "\t", $line, -1;
			shift(@$table_colnames);
			
			while($line = <$fh>) {
			
				if($line =~/^!platform_table_end$/) {
					last;
				}
			
				chomp $line;
				my @tmp = split "\t", $line, -1;
				
				my $uid = shift(@tmp);
				
				push(@$table_rownames, $uid);
				push(@$table_matrix, [@tmp]);
				
			}
			
			
		}
		if($line =~/^!platform_table_end$/) {
			last;
		}
		
	}
	
	my $n_row = len($table_rownames);
	my $n_col = len($table_colnames);
	
	my $platform = $accession;
	
	print "Platform info:\n";
	print "  Accession: $accession\n";
	print "  Platform: $platform\n";
	print "  Title: $title\n";
	print "  Rows: $n_row\n";
	print "  Columns: $n_col\n";
	print "\n";
	
	$self->set_meta( accession => $accession,
	                 title     => $title,
					 platform  => $platform );
	$self->set_table( rownames => $table_rownames,
	                  colnames => $table_colnames,
					  matrix   => $table_matrix );
	
	Microarray::GEO::SOFT::_set_to_std_fh();
	
	return $self;
}

# map new ID from the order of the first column
sub _mapping {

	my $self = shift;
	my $to_id = shift;
	my $from_list = shift;
	
	my $mapping;
	
	my $to_index;
	my $colnames = $self->colnames;
	for(my $i = 0; $i < len($colnames); $i ++) {
		if($colnames->[$i] eq $to_id) {
			$to_index = $i;
			last;
		}
	}
	
	if(! defined($to_index)) {
		croak "ERROR: Cannot find ID ($to_id) in ".$self->platform."\n";
	}
	
	my $mat = $self->matrix;
	my $hash;
	my $rownames = $self->rownames;
	for(my $i = 0; $i < len($mat); $i ++) {
		if($mat->[$i]->[$to_index] =~/^(.*?)\/\/\//) {
			$hash->{$rownames->[$i]} = $1;
		}
		else {
			$hash->{$rownames->[$i]} = $mat->[$i]->[$to_index];
		}
	}
	
	for (@$from_list) {
		push(@$mapping, $hash->{$_});
	}

	return $mapping;
	
}


__END__

=pod

=head1 NAME

Microarray::GEO::SOFT::GPL - GEO platform data class

=head1 SYNOPSIS

  use Microarray::GEO::SOFT:
  my $soft = Microarray::GEO::SOFT->new("file" => "GPL15181.soft");
  
  # or you can download from GEO FTP site
  my $soft = Microarray::GEO::SOFT->new;
  $soft->download("GPL15181");
  
  # since you use a GPL id
  # $gpl is a Microarray::GEO::SOFT::GPL class object
  my $gpl = $soft->parse;
  
  # the meta information
  $gpl->meta;
  $gpl->platform;
  $gpl->title;
  $gpl->accession;
  
  # the platform data is a matrix
  $gpl->matrix;
  # the names for each column, it is gene id types
  $gpl->colnames;
  # the names for each row, it is the primary id for rows
  # e.g. probe IDs
  $gpl->rownames;
  
  # we want to get other ID for microarray data
  my $other_id = $gpl->mapping("miRNA_ID");
  # or
  my $other_id = $gpl->mapping($gpl->colnames->[1]);

=head1 DESCRIPTION

A Platform record is composed of a summary description of the array or sequencer and, 
for array-based Platforms, a data table defining the array template.Each Platform 
record is assigned a unique and stable GEO accession number (GPLxxx). 
A Platform may reference many Samples that have been submitted by multiple submitters.
(Copyed from GEO web site).

This module is a simple tool to parse and store platform data. We only extract the most
compact meta information and the id matrix for id mapping. Platform data is downloaded
from ftp://ftp.ncbi.nih.gov/pub/geo/DATA/annotation/platforms/GPLxxx.annot.gz. This 
module will not be used directly but always be invoked by L<Microarray::GEO::SOFT> module.

=head2 Subroutines

=over 4

=item C<new("file" =E<gt> $file, "verbose" => 1)>

Initial a GPL class object. The file argument is the platform data in SOFT format
or a file handle that has been openned. 'verbose' determines whether
print the message when analysis. 'sample_value_column' is the column name for
table data when parsing GSM data. The argument is optional and the platform
can be download through L<Microarray::GEO::SOFT>.

=item C<$gpl-E<gt>parse>

Retrieve platform information. This soubroutine extracts the basic meta information
and a table with different ID types.

=item C<$gpl-E<gt>meta>

Get meta information

=item C<$gpl-E<gt>set_meta(HASH)>

Set meta information. Valid argumetns are 'accession', 'title' and 'platform'.

=item C<$gpl-E<gt>table>

Get table information

=item C<$gpl-E<gt>set_table>

Set table information. Valid argumetns are 'rownames', 'colnames' and 'matrix'.

=item C<$gpl-E<gt>platform>

Accession number for the platform

=item C<$gpl-E<gt>title>

Title of the platform record

=item C<$gpl-E<gt>accession>

Accession number for the platform

=item C<$gpl-E<gt>rownames>

primary ID for probes in the platform

=item C<$gpl-E<gt>colnames>

Different ID types provided in the platform data

=item C<$gpl-E<gt>matrix>

ID type matrix, each column refers to one ID type

=back

=head1 AUTHOR

Zuguang Gu E<lt>jokergoo@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Zuguang Gu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Microarray::GEO::SOFT>

=cut
