package Microarray::File::Data::Manor_Output;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.8';

# not yet tested

{ package manor_clone_level;

	require Microarray::File;

	our @ISA = qw( simple_delimited_file );

	sub import_data {
		my $self = shift;
		my $aaData = $self->load_file_data;	# from package delimited_file
		my $line_num = @$aaData;
		$self->line_num($line_num-1);	# ignore column header
		$self->sort_data($aaData);
		$self->set_manor_data;
	}
	sub get_data {
		my $self = shift;
		if (wantarray()) {
			return ($self->get_all_locations,$self->get_all_log2,$self->get_all_bacs);
		} elsif (defined wantarray()) {	# scalar context
			my $hData = { };
			my $aChr = $self->chromosomes_seen;
		    for my $chr (@$aChr){
		    	$hData->{ $chr } = [$self->get_locations($chr),$self->get_log2($chr),$self->get_bacs($chr)];
		    }
		    return $hData;
		}
	}
	sub set_manor_data {
		my $self = shift;
		
		my $aaData = $self->get_imported_data;
		
		# get which column indexes of the data we'll be using
		my $log_col 	= $self->get_column_id('LogRatio');
		my $locn_col 	= $self->get_column_id('Position');
		my $chrom_col 	= $self->get_column_id('Chromosome');
		my $bac_col 	= $self->get_column_id('Name');

		my $last_name = "";
		my %hChromosomes = ();
		
		for my $aData_Row (@$aaData){
			my $bac_name = $aData_Row->[$bac_col];
			next if ($last_name eq $bac_name);
			$last_name = $bac_name;

			my $log2 = $aData_Row->[$log_col];			# spot log2 ch1/ch2 value
			next if ($log2 eq 'NA');

			my $chromosome = $aData_Row->[$chrom_col];
			my $chr_locn = $aData_Row->[$locn_col];		# bp location
			$self->set_values($chromosome,$chr_locn,$log2,$bac_name);
			$hChromosomes{ $chromosome }++;
		}
		my @aChromosomes = keys %hChromosomes;
		$self->chromosomes_seen(\@aChromosomes);
	}
	sub set_values {
		my $self = shift;
		my ($chromosome,$chr_locn,$log2,$bac_name) = @_;
		
		my $aLocns = $self->get_locations($chromosome);
		my $aLog2 = $self->get_log2($chromosome);
		my $aBacs = $self->get_bacs($chromosome);
		
		push(@$aLocns,$chr_locn);
		push(@$aLog2,$log2);
		push(@$aBacs,$bac_name);
	}
	sub get_locations {
		my $self = shift;
		my $chr = shift;
		unless(defined $self->{ "_locns_$chr" }){
			$self->{ "_locns_$chr" } = [];
		}
		return $self->{ "_locations_$chr" };
	}
	sub get_log2 {
		my $self = shift;
		my $chr = shift;
		unless(defined $self->{ "_log2_$chr" }){
			$self->{ "_log2_$chr" } = [];
		}
		return $self->{ "_log2_$chr" };
	}
	sub get_bacs {
		my $self = shift;
		my $chr = shift;
		unless(defined $self->{ "_bacs_$chr" }){
			$self->{ "_bacs_$chr" } = [];
		}
		return $self->{ "_bacs_$chr" };
	}
	sub get_all_locations {
		my $self = shift;
		unless(defined $self->{ _all_locns }){
			my $aLocations = [];
			for my $chr ((1..24)){
				my $aChr_Locn = $self->get_locations($chr);
				my @aLocn = map $_ + genomic_locn($chr), @$aChr_Locn;
				push(@$aLocations,\@aLocn);
			}
			$self->{ _all_locns } = $aLocations;
		}
		$self->{ _all_locns };
	}
	sub get_all_log2 {
		my $self = shift;
		unless(defined $self->{ _all_log2 }){
			my $aLog2 = [];
			for my $chr ((1..24)){
				push(@$aLog2,$self->get_log2($chr));
			}
			$self->{ _all_log2 } = $aLog2;
		}
		$self->{ _all_log2 };
	}
	sub get_all_bacs {
		my $self = shift;
		unless(defined $self->{ _all_bacs }){
			my $aBacs = [];
			for my $chr ((1..24)){
				push(@$aBacs,$self->get_bacs($chr));
			}
			$self->{ _all_bacs } = $aBacs;
		}
		$self->{ _all_bacs };
	}
	sub chromosomes_seen {
		my $self = shift;
		@_	?	$self->{ _chromosomes_seen } = shift
			:	$self->{ _chromosomes_seen };
	}
	sub chr_length {	# NCBI36 figures
		my $chromosome = shift;
		my %hLengths = (		
			1 => 247249719,
			2 => 242951149,
			3 => 199501827,
			4 => 191273063,
			5 => 180857866,
			6 => 170899992,
			7 => 158821424,
			8 => 146274826,
			9 => 140273252,
			10 => 135374737,
			11 => 134452384,
			12 => 132349534,
			13 => 114142980,
			14 => 106368585,
			15 => 100338915,
			16 => 88827254,
			17 => 78774742,
			18 => 76117153,
			19 => 63811651,
			20 => 62435964,
			21 => 46944323,
			22 => 49691432,
			23 => 154913754,
			24 => 57772954	# TOTAL=3080419480
		);
		return $hLengths{$chromosome};
	} 
	sub genomic_locn {	# NCBI36 figures
		my $chromosome = shift;
		my $location = shift;
		my %hChromosome = (		
			# start bp			# length
			1 => 0,				# 247249719
			2 => 247249720,		# 242951149
			3 => 490200869,		# 199501827
			4 => 689702696,		# 191273063
			5 => 880975759,		# 180857866
			6 => 1061833625,	# 170899992
			7 => 1232733617,	# 158821424
			8 => 1391555041,	# 146274826
			9 => 1537829867,	# 140273252
			10 => 1678103119,	# 135374737
			11 => 1813477856,	# 134452384
			12 => 1947930240,	# 132349534
			13 => 2080279774,	# 114142980
			14 => 2194422754,	# 106368585
			15 => 2300791339,	# 100338915
			16 => 2401130254,	# 88827254
			17 => 2489957508,	# 78774742
			18 => 2568732250,	# 76117153
			19 => 2644849403,	# 63811651
			20 => 2708661054,	# 62435964
			21 => 2771097018,	# 46944323
			22 => 2818041341,	# 49691432
			23 => 2867732773,	# 154913754
			24 => 3022646527,	# 57772954	TOTAL=3080419480
			25 => 3080419480
		);
		return $hChromosome{$chromosome};
	} 
	
}

1;

__END__

=head1 NAME

Microarray::File::Data::Manor_Output - A Perl module for managing 'Manor' clone and spot level output 

=head1 SYNOPSIS

	use Microarray::File::Data::Manor_Output;

	my $manor_file = manor_clone_level->new("/file.csv");

=head1 DESCRIPTION

To be added.

=head1 METHODS

To be added.

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::File|Microarray::File>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

