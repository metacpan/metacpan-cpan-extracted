package Microarray::File::Clone_Locns;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.8';

require Microarray::File;

{ package clone_locn_file;

	our @ISA = qw( microarray_text_file );

	sub import_data {
		my $self = shift;
		$self->make_clone_hash;
	}
	sub make_clone_hash {
		my $self = shift;
		my $source = $self->get_source;
		$source =~ s/"//g;
		my @aRows = split(/\n/,$source);
		$self->line_num(scalar @aRows);
		
		my %hClones = ();
		for my $row (@aRows){
			my ($name,$locn,$chr) = split(/;/,$row);
			$hClones{ $name } = { 
				_chr => $chr,
				_locn => $locn
			};
		}
		$self->{ _clones } = \%hClones;
	}
	sub clone_number {
		my $self = shift;
		$self->line_num;
	}
	sub clone_hash {
		my $self = shift;
		if (@_){
			my $clone = shift;
			my $hClones = $self->{ _clones };
			return $hClones->{ $clone };
		} else {
			$self->{ _clones };
		}
	}
	sub chromosome {
		my $self = shift;
		my $hClone = $self->clone_hash(shift);
		return $hClone->{ _chr };
	}
	sub location {
		my $self = shift;
		my $hClone = $self->clone_hash(shift);
		return $hClone->{ _locn };
	}
	sub chr_location {
		my $self = shift;
		my $clone = shift;
		return ($self->chromosome($clone), $self->location($clone));
	}
	sub genomic_locn {	# ensembl build 36 figures
		my $self = shift;
		my $clone = shift;
		if ((my $chr = $self->chromosome($clone)) && (my $locn = $self->location($clone))){
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
				23 => 2867732773,	# 154913754	X-alternative
				24 => 3022646527,	# 57772954	Y-alternative
				X => 2867732773,	# 154913754
				Y => 3022646527		# 57772954	TOTAL=3080419480
			);
			return unless (defined $hChromosome{$chr});
			return $hChromosome{$chr} + $locn;
		}
	} 
}


1;


__END__

=head1 NAME

Microarray::File::Clone_Locns - An object oriented Perl module describing a genomic clone location file

=head1 SYNOPSIS

	use Microarray::File::Clone_Locns;

	my $oFile = clone_locn_file->new('/clone_locns.txt');
	my ($chr,$location) = $oFile->chr_location($clone);

=head1 DESCRIPTION

Microarray::File::Clone_Locns provides methods for retrieving data from a genomic clone location file. Each row of the file contains a clone name and its genomic location in the format C<'Name;bp;chr'> (e.g. C<'RP11-23C5;7853570;4'>. The sex chromosomes can be denoted X and Y or 23 and 24.  

=head1 METHODS

Pass each of the methods a reporter name to return the relevant value.

=over

=item B<chromosome()>

The chromosome name/number. 

=item B<location()>

The bp location of the centre of the clone, where 0 is the chromosome p-ter. 

=item B<genomic_locn()>

The bp location of the centre of the clone with respect to the entire genome, where 0 is chromosome 1pter.

=item B<chr_location()>

Returns (chromosome,location)

=item B<clone_number>

The number of clones listed in the file

=back

=head1 SEE ALSO

L<Microarray::File|Microarray::File>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

