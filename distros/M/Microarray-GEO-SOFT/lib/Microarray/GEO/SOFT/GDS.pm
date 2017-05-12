package Microarray::GEO::SOFT::GDS;

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
	             "use_identifier" => 0,
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
	
	$self->_parse_dataset($fh);
	
	return 1;
}

sub _parse_dataset {

	my $self = shift;

	my $fh = shift;
	
	Microarray::GEO::SOFT::_set_fh($self->{verbose});
	
	my $accession;
	my $title;
	my $platform;
	my $field_explain;
	my $table_colnames = [];
	my $table_rownames = [];
	my $table_colnames_explain_hash = {};
	my $table_matrix = [];
	
	while(my $line = <$fh>) {
		
		chomp $line;
		if($line =~/^\^DATASET = (GDS\d+)$/) {
			$accession = $1;
		}
		
		if($line =~/^!dataset_title = (.*?)$/) {
			$title = $1;
		}
		
		if($line =~/^!dataset_platform = (GPL\d+)$/) {
			$platform = $1;
		}
		
		if($line =~/^#(GSM\d+) = (Value for GSM\d+: )?(.*?)$/) {
			$table_colnames_explain_hash->{$1} = $3;
		}
		
		if($line =~/^!dataset_table_begin$/) {
			
			$line = <$fh>;
			chomp $line;
			
			@$table_colnames = split "\t", $line, -1;
			shift(@$table_colnames);
			shift(@$table_colnames);
			
			while($line = <$fh>) {
			
				if($line =~/^!dataset_table_end$/) {
					last;
				}
			
				chomp $line;
				my @tmp = split "\t", $line, -1;
				
				my $uid = shift(@tmp);
				
				# the second column in the matrix is identifier
				my $identifier = shift(@tmp);
				
				# do not recommond to use identifier
				# it is better to convert IDs using id_convert subroutine
				if($self->{use_identifier}) {
					push(@$table_rownames, $identifier);
				}
				else {
					push(@$table_rownames, $uid);
				}
				push(@$table_matrix, [@tmp]);

			}
			
			
		}
		if($line =~/^!dataset_table_end$/) {
			last;
		}
		
	}
	
	my $n_row = len($table_rownames);
	my $n_col = len($table_colnames);
	
	my $table_colnames_explain = [];
	for (@$table_colnames) {
		push(@$table_colnames_explain, $table_colnames_explain_hash->{$_});
	}
	
	print "Dataset info:\n";
	print "  Accession: $accession\n";
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
					  colnames_explain => $table_colnames_explain,
					  matrix   => $table_matrix );
	
	Microarray::GEO::SOFT::_set_to_std_fh();
	
	return $self;

}

sub get_subset {
	
	my $self = shift;
	my $arg = {"byrow" => rep(1, len($self->rownames)),
	           "bycol" => rep(1, len($self->colnames)),
			   @_};
	
	$arg->{byrow} = sapply($arg->{byrow}, sub{($_[0] != 0)+0});
	$arg->{bycol} = sapply($arg->{bycol}, sub{($_[0] != 0)+0});
	
	if(len($arg->{byrow}) != len($self->rownames)
	   or len($arg->{bycol}) != len($self->colnames)) {
	   
		croak "ERROR: Do not fit the dimension of the matrix";
	}
	
	if(sum($arg->{bycol}) == len($self->colnames)) {
		$self->set_table( rownames => subset($self->rownames, which($arg->{byrow})),
		                  matrix => subset($self->matrix, which($arg->{byrow})) );
	}
	else {
		my $new_matrix = sapply($self->matrix, sub { subset($_[0], which($arg->{bycol})) });
		$new_matrix = subset($new_matrix, which($arg->{byrow}));
		$self->set_table( rownames => subset($self->rownames, which($arg->{byrow})),
		                  colnames => subset($self->colnames, which($arg->{bycol})),
		                  colnames_explain => subset($self->colnames_explain, which($arg->{bycol})),
		                  matrix => $new_matrix );
		
	}
	
	return $self->soft2exprset;
	
}

sub id_convert {

	my $self = shift;
	my $gpl = shift;
	my $to_id = shift;
	
	if($self->{use_identifier}) {
		croak "ERROR: You are not suitable to use 'id_convert' since you have set use_identifier to TURE. You can only use 'soft2expr' for further analysis.";
	}
	
	my $platform_id = $gpl->accession;
	
	if(ref($to_id) eq "Regexp") {
		my @match = grep {/$to_id/} @{$gpl->colnames};
		if(!scalar(@match)) {
			croak "ERROR: Cannot find ID ($to_id) in $platform_id\n";
		}
		elsif(scalar(@match) > 1) {
			carp "WARNING: Find more than one matched ID types (".(join ", ", @match).") under $to_id, only take the first one ($match[0])";
			$to_id = $match[0];
		}
		else {
			$to_id = $match[0];
		}
	}
	else {
		if(! is_element($to_id, $gpl->colnames)) {
			croak "ERROR: Cannot find ID ($to_id) in $platform_id\n";
		}
	}
	
	my $new_rownames = $gpl->_mapping($to_id, $self->rownames);
	my $eset = Microarray::ExprSet->new;
	$eset->set_feature($new_rownames);
	$eset->set_phenotype($self->colnames_explain);
	$eset->set_matrix($self->matrix);
	
	return $eset;

}

# change SOFT to ExprSet
# in fact, it is only for GDS
sub soft2exprset {

	my $self = shift;

	my $eset = Microarray::ExprSet->new;
	$eset->set_feature($self->rownames);
	$eset->set_phenotype($self->colnames_explain);
	$eset->set_matrix($self->matrix);
	
	return $eset;
	
}



__END__

=pod

=head1 NAME

Microarray::GEO::SOFT::GDS - GEO data set data class

=head1 SYNOPSIS

  use Microarray::GEO::SOFT:
  my $soft = Microarray::GEO::SOFT->new;
  $soft->download("GDS3719");
  
  my $gds = $soft->parse;
  
  # the meta information
  $gds->meta;
  $gds->platform;
  $gds->title;
  $gds->accession;
  
  # the sample data is a matrix
  $gds->matrix;
  # the names for each column
  $gds->colnames;
  $ the names for each row, it is the primary id for rows
  $gds->rownames;

=head1 DESCRIPTION

A DataSet represents a curated collection of biologically and statistically 
comparable GEO Samples and forms the basis of GEO's suite of data display and analysis tools.
Samples within a DataSet refer to the same Platform, that is, they share a common
 set of array elements. Value measurements for each Sample within a DataSet are 
 assumed to be calculated in an equivalent manner, that is, considerations such as 
 background processing and normalization are consistent across the DataSet. 
 Information reflecting experimental factors is provided through DataSet subsets. 
 (Copyed from GEO web site).
 
This module retrieves data storing as GEO data set format. We take this as the basic
microarray data format (expression matrix).

=head2 Subroutines

=over 4

=item C<new("file" =E<gt> $file, "use_identifier" =E<gt> 0, "verbose" => 1)>

Initial a GDS class object. The first argument is the path of the microarray data in SOFT format
or a file handle that has been openned. The argument is optional and the platform
can be download through L<Microarray::GEO::SOFT>. Since gene identifiers have been
integrated into the SOFT file, so user can shoose whether to take probe ID or identifiers
as the primary ID. We do not accommendate to set 'use_identifier' to TURE becaure 'id_convert'
will not work if set the value to TURE. 'verbose' determines whether
print the message when analysis. 'sample_value_column' is the column name for
table data when parsing GSM data.

=item C<$gds-E<gt>parse>

Retrieve data set information from microarray data. The data set in SOFT format
is alawys a table

=item C<$gds-E<gt>meta>

Get meta information

=item C<$gds-E<gt>set_meta(HASH)>

Set meta information. Valid argumetns are 'accession', 'title' and 'platform'.

=item C<$gds-E<gt>table>

Get table information

=item C<$gds-E<gt>set_table>

Set table information. Valid argumetns are 'rownames', 'colnames', 'colname_explain' and 'matrix'.

=item C<$gds-E<gt>platform>

Accession number for the platform the data set belong to.

=item C<$gds-E<gt>title>

Title of the data set record

=item C<$gds-E<gt>accession>

Accession number for the data set

=item C<$gds-E<gt>rownames>

primary ID for probes

=item C<$gds-E<gt>colnames>

Different sample names or experiment designs

=item C<$gds-E<gt>colnames_explain>

A little more detailed explain for column names

=item C<$gds-E<gt>matrix>

expression value matrix

=item C<$gds-E<gt>id_convert($gpl, $to_id)>

Transfrom the primary ID to a new ID type. The first argument is a L<Microarray::GEO::SOFT::GPL>
class object that the GDS belongs to. The second argument is the ID that would map to.
It is one of the colnames of C<$gpl>. Also a regexp is accepted. It returns a 
L<Microarray::ExprSet> object.

=item C<$gds-E<gt>soft2exprset>

Transform L<Microarray::GEO::SOFT::GDS> class object to L<Microarray::ExprSet> class object.

=item C<$gds-E<gt>get_subset(HASH)>

Get subset of rows and columns in the expression matrix. Valid arguments are 'byrow' and 'bycol'.
the value for these two arguments should be array reference where the length should be equal to
the length of rownames or colnames of the matrix respectively. The value in the array should be 
either TRUE(1) or FALSE(0) to indicate whether take or drop the corresponding position in the matrix.
It returns a L<Microarray::ExprSet> object.

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

