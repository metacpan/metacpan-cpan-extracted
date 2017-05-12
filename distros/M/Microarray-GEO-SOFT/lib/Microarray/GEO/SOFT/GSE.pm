package Microarray::GEO::SOFT::GSE;

use List::Vectorize qw(!table);
require Microarray::GEO::SOFT::GPL;
require Microarray::GEO::SOFT::GSM;
require Microarray::GEO::SOFT::GDS;
use Carp;
use strict;

use base "Microarray::GEO::SOFT";

our $GDS_MERGE = 0;

1;

sub new {

	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = { "file" => "",
	             "verbose" => 1,
				 "sample_value_column" => 'VALUE',
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
	
	$self->_parse_series($fh);
	
	return $self;
}

sub _parse_series {

	my $self = shift;

	my $fh = shift;
	
	Microarray::GEO::SOFT::_set_fh($self->{verbose});
	
	my $accession;
	my $title;
	my $platform;
	
	my $series;

	my $gpl_list;
	my $gsm_list;
	
	while(my $line = <$fh>) {
	
		chomp $line;
		
		if($line =~/^\^SERIES = (GSE\d+)$/) {
			$accession = $1;
		}
		
		if($line =~/^!Series_title = (.*?)$/) {
			$title = $1;
		}
		
		if($line =~/^!Series_platform_id = (GPL\d+)$/) {
			push(@$platform, $1);
		}
		
		# platform part in the file
		elsif($line =~/^\^PLATFORM = (GPL\d+)$/) {
		
			$fh = _back_to_last_line($fh, length($line));
			
			# it is a GPL object
			my $gpl = Microarray::GEO::SOFT::GPL->new(file => $fh,
			                                          verbose => $self->{verbose});
			$gpl->parse;
			
			push(@$gpl_list, $gpl);
		}
		# sample part in the file
		elsif($line =~/^\^SAMPLE = (GSM\d+)$/) {
		
			$fh = _back_to_last_line($fh, length($line));
			
			# it is a GSM object
			my $gsm = Microarray::GEO::SOFT::GSM->new(file => $fh,
			                                          verbose => $self->{verbose},
													  sample_value_column => $self->{sample_value_column});
			$gsm->parse;
			
			push(@$gsm_list, $gsm);
			
		}
	}
	
	my $n_platform = len($gpl_list);
	my $n_sample = len($gsm_list);
	
	print "Series info:\n";
	print "  Accession: $accession\n";
	print "  Title:$title\n";
	print "  Platforms: $n_platform\n";
	print "  Samples: $n_sample\n";
	print "\n";
	
	$self->set_meta( accession => $accession,
	                 title     => $title,
					 platform  => $platform );
	$self->set_list("GPL" => $gpl_list,
	                "GSM" => $gsm_list);
	
	Microarray::GEO::SOFT::_set_to_std_fh();
	
	return $self;
}


sub _back_to_last_line {
	
	my $fh = shift;
	my $current_line_length = shift;
	
	my $position = tell($fh);
	seek($fh, $position - $current_line_length - 2, 0);
	
	return $fh;
}

sub set_list {

	my $self = shift;
	
	my $arg = {'GPL' => $self->list('GPL'),
	           'GSM' => $self->list('GSM'),
			   @_};
	
	$self->{"GPL_list"} = $arg->{'GPL'};
	$self->{"GSM_list"} = $arg->{'GSM'};
	
	return $self;
}

sub list {
	
	my $self = shift;
	my $type = shift;
	
	if($type ne 'GPL' and $type ne 'GSM') {
		croak "ERROR $type is not a valid paramter. Permitted argumetns are GPL and GSM.";
	}
	
	return defined($self->{$type.'_list'}) ? $self->{$type.'_list'}
	                                       : undef ;

}

# override these method inherited from SUPER class
BEGIN {
	
	no strict 'refs';

	for my $accessor (qw(table rownames colnames colnames_explain matrix set_table)) {
		*{$accessor} = sub {
			croak "Method '".$accessor."' is not supported by ".__PACKAGE__." because a series can contain more than one platforms\n";
		}
	}
}

# merge samples under same platform as a matrix
# this is what is called GDS
# since some series contain more than one platforms
# thus, this function returns a GDS object array reference
sub merge {
		
	my $self = shift;
	
	my $gpl_list = $self->platform;
	my $gds_list;
	
	for(my $i = 0; $i < len($gpl_list); $i ++) {
	
		my $sample_list = $self->list("GSM");
		
		# list of GSMs with same platform
		my $s = subset($sample_list, sub {$_[0]->platform eq $gpl_list->[$i]} );
		
		my $g = $self->_merge_gsm($s);

		push(@$gds_list, $g);
	}
	
	return $gds_list;
	
}

sub _merge_gsm {

	my $self = shift;
	
	my $gsm_list = shift;
	
	Microarray::GEO::SOFT::_set_fh($self->{verbose});
	
	# check whether these samples share same platform
	my $gpl_list = sapply($gsm_list, sub {$_[0]->platform});
	if(len(unique($gpl_list)) != 1) {
		croak "ERROR: Platform should be same\n";
	}
	
	# virtual GDS has a long accession number
	$GDS_MERGE ++;
	my $accession = "GDS_merge_$GDS_MERGE"."_from_".$self->accession;
	my $title = "merged from ".$self->accession." under ".$gpl_list->[0];
	my $platform = $gpl_list->[0];
	my $table_colnames;
	my $table_colnames_explain;
	
	for(my $i = 0; $i < len($gsm_list); $i ++) {

		$table_colnames->[$i] = $gsm_list->[$i]->accession;
		$table_colnames_explain->[$i] = $gsm_list->[$i]->title;
		
	}

	my $table_rownames = $gsm_list->[0]->rownames;
	
	my $table_matrix = [[]];
	for(my $i = 0; $i < len($gsm_list); $i ++) {
		for(my $j = 0; $j < len($table_rownames); $j ++) {
			$table_matrix->[$j]->[$i] = $gsm_list->[$i]->matrix->[$j]->[0];
		}
	}
	
	
	my $n_row = len($table_rownames);
	my $n_col = len($table_colnames);
	
	print "Merge GSM into GDS:\n";
	print "  Accession: $accession\n";
	print "  Platform: $platform\n";
	print "  Title: $title\n";
	print "  Rows: $n_row\n";
	print "  Columns: $n_col\n";
	print "\n";
	
	my $gds = Microarray::GEO::SOFT::GDS->new();
	$gds->set_meta( accession => $accession,
	                title     => $title,
					platform  => $platform );
	$gds->set_table( rownames => $table_rownames,
	                 colnames => $table_colnames,
					 colnames_explain => $table_colnames_explain,
					 matrix   => $table_matrix );
	
	Microarray::GEO::SOFT::_set_to_std_fh();
	
	return $gds;
}


__END__

=pod

=head1 NAME

Microarray::GEO::SOFT::GSE - GEO series data class

=head1 SYNOPSIS

  use Microarray::GEO::SOFT:
  my $soft = Microarray::GEO::SOFT->new("file" => "GSE35505.soft");
  
  # or you can download from GEO website
  my $soft = Microarray::GEO::SOFT->new;
  $soft->download("GSE35505");
  
  # $gse is a Microarray::GEO::SOFT::GSE class object
  my $gse = $soft->parse;
  
  # the meta information
  $gse->meta;
  $gse->platform;
  $gse->title;
  $gse->accession;
	
  # since a GSE can contain more than one GSM and GPL, so the GPL and GSM stored
  # in GSE is a list or array
  my $samples = $gse->list("GSM");
  my $platforms = $gse->list("GPL");
  
  # data in single GSM can be merged as matrix by platforms
  # it is a GDS class object
  my $g = $gse->merge->[0];

=head1 DESCRIPTION

A Series record links together a group of related Samples and provides a focal point 
and description of the whole study. Series records may also contain tables describing 
extracted data, summary conclusions, or analyses. Each Series record is assigned a unique 
and stable GEO accession number (GSExxx). (Copyed from GEO web site).

This module retrieves data storing as GEO series format.

=head2 Subroutines

=over 4

=item C<new("file" =E<gt> $file, "verbose" => 1)>

Initial a GSE class object. The only argument is the microarray data in SOFT format
or a file handle that has been openned. The argument is optional and the platform
can be download through L<Microarray::GEO::SOFT>. 'verbose' determines whether
print the message when analysis. 'sample_value_column' is the column name for
table data when parsing GSM data.

=item C<$gse-E<gt>parse>

Retrieve series information. This subroutine extracts the basic meta information and 
the L<Microarray::GEO::SOFT::GSM> list and the L<Microarray::GEO::SOFT::GPL> list

=item C<$gse-E<gt>meta>

Get meta information

=item C<$gse-E<gt>set_meta(HASH)>

Set meta information. Valid argumetns are 'accession', 'title' and 'platform'.

=item C<$gse-E<gt>table>

disabled

=item C<$gse-E<gt>set_table>

disabled

=item C<$gse-E<gt>platform>

Accession number for the platform the series belong to. Note here the platform is an array reference.

=item C<$gse-E<gt>title>

Title of the series record

=item C<$gse-E<gt>accession>

Accession number for the series

=item C<$gse-E<gt>rownames>

disabled

=item C<$gse-E<gt>colnames>

disabled

=item C<$gse-E<gt>colnames_explain>

disabled

=item C<$gse-E<gt>matrix>

disabled

=item C<$gse-E<gt>list("GSM" | "GPL")>

Since a series can contain more than one samples and platforms. This method can
get GSM list or GPL list that belong to the GSE record.

=item C<$gse-E<gt>set_list(HASH)>

Set the GSM and GPL list to GSE object. Valid arguments are 'GPL' and 'GSM'.

=item C<$gse-E<gt>merge>

merge single GSMs into a expression value matrix. The merging process is by platforms.
Each matrix is a GDS class object.

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

