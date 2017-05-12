package Microarray::GEO::SOFT::GSM;

# parse SOFT file
# get the GSM part, only the first record of GSM from the current position to read

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
				 "sample_value_column" => "VALUE",
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
	
	$self->_parse_sample($fh);
	
	return 1;
}

sub _parse_sample {

	my $self = shift;

	my $fh = shift;
	
	Microarray::GEO::SOFT::_set_fh($self->{verbose});
	
	my $accession;
	my $title;
	my $platform;
	my $table_colnames = [];
	my $table_rownames = [];
	my $table_matrix = [];

	while(my $line = <$fh>) {
		
		chomp $line;
		if($line =~/^!Sample_geo_accession = (GSM\d+)$/) {
			$accession = $1;
		}
		
		elsif($line =~/^!Sample_title = (.*?)$/) {
			$title = $1;
		}
		
		elsif($line =~/^!Sample_platform_id = (GPL\d+)$/) {
			$platform = $1;
		}
		
		elsif($line =~/^!sample_table_begin$/) {
			
			$line = <$fh>;
			chomp $line;
			
			@$table_colnames = split "\t", $line, -1;
			shift(@$table_colnames);
			
			my $value_index = -1;
			for(my $i = 0; $i < len($table_colnames); $i ++) {
				if($table_colnames->[$i] eq $self->{sample_value_column}) {
					$value_index = $i;
					last;
				}
			}
			
			if($value_index == -1) {
				croak "ERROR: Cannot find sample value column ($self->{sample_value_column}).";
			}
			
			while($line = <$fh>) {
			
				if($line =~/^!sample_table_end$/) {
					last;
				}
			
				chomp $line;
				my @tmp = split "\t", $line, -1;
				
				my $uid = shift(@tmp);
				
				push(@$table_rownames, $uid);
				# one column matrix
				push(@$table_matrix, [$tmp[$value_index]]);
			}
			
			
		}
		
		if($line =~/^!sample_table_end$/) {
			last;
		}
		
	}
	
	my $n_row = len($table_rownames);
	my $n_col = len($table_colnames);
	
	print "Sample info:\n";
	print "  Accession: $accession\n";
	print "  Platform: $platform\n";
	print "  Title: $title\n";
	print "  Rows: $n_row\n";
	print "  Columns: $n_col\n";
	print "\n";
	
	#my $table_rownames_sorted = sort_array($table_rownames, sub {$_[0] cmp $_[1]});
	#my $table_rownames_sorted_index = order($table_rownames, sub {$_[0] cmp $_[1]});
	#my $table_matrix_sorted = subset($table_matrix, $table_rownames_sorted_index);
	
	$self->set_meta( accession => $accession,
	                 title     => $title,
					 platform  => $platform );
	$self->set_table( rownames => $table_rownames,
	                  colnames => $table_colnames,
					  matrix   => $table_matrix );
	
	Microarray::GEO::SOFT::_set_to_std_fh();
	
	return $self;

}


__END__

=pod

=head1 NAME

Microarray::GEO::SOFT::GSM - GEO sample data class

=head1 SYNOPSIS

  use Microarray::GEO::SOFT:
  my $soft = Microarray::GEO::SOFT->new;
  $soft->download("GSE35505");
  
  my $gse = $soft->parse;
  my $gsm = $gse->list("GSM")->[0];
  
  # the meta information
  $gsm->meta;
  $gsm->platform;
  $gsm->title;
  $gsm->accession;
  
  # the sample data is a matrix (in fact it is a vector)
  $gsm->matrix;
  # the names for each column
  $gsm->colnames;
  $ the names for each row, it is the primary id for rows
  $gsm->rownames;

=head1 DESCRIPTION

A Sample record describes the conditions under which an individual Sample was handled, 
the manipulations it underwent, and the abundance measurement of each element derived 
from it. Each Sample record is assigned a unique and stable GEO accession number (GSMxxx).
 A Sample entity must reference only one Platform and may be included in multiple Series.
(Copyed from GEO web site).

This module retrieves sample information from series data.

=head2 Subroutines

=over 4

=item C<new("file" =E<gt> $file, "verbose" => 1, 'sample_value_column' => 'VALUE')>

Initial a GSM class object. The first argument is the path of the sample data in SOFT format
or a file handle that has been openned. 'verbose' determines whether
print the message when analysis. 'sample_value_column' is the column name for
table data when parsing GSM data.

=item C<$gsm-E<gt>parse>

Retrieve sample information. The sample data in SOFT format is alawys a table

=item C<$gsm-E<gt>meta>

Get meta information

=item C<$gsm-E<gt>set_meta(HASH)>

Set meta information. Valid argumetns are 'accession', 'title' and 'platform'.

=item C<$gsm-E<gt>table>

Get table information

=item C<$gsm-E<gt>set_table>

Set table information. Valid argumetns are 'rownames', 'colnames', 'colname_explain' and 'matrix'.

=item C<$gsm-E<gt>platform>

Accession number for the platform the sample belong to.

=item C<$gsm-E<gt>title>

Title of the series record

=item C<$gsm-E<gt>accession>

Accession number for the sample

=item C<$gsm-E<gt>rownames>

primary ID for probes

=item C<$gsm-E<gt>colnames>

C<['VALUE']>

=item C<$gsm-E<gt>matrix>

expression value matrix. It is a one column matrix here.

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

