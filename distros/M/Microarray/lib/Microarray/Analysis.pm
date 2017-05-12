package Microarray::Analysis;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.4';

{ package analysis;

	sub new {
		my $class = shift;
		if (@_) {
			my $data_source = shift;
			my $self = { _data_source => $data_source };
			bless $self, $class;
			return $self;
		} else {
			die "Microarray::Analysis ERROR: Data Source Required to Create a New Analysis Object";
		}
	}
	sub DESTROY {
		my $self = shift;
	}  
	sub data_source {
		my $self = shift;
		$self->{_data_source};
	}

	sub analysis_results {
		my $self = shift;
		$self->{_analysis_results};
	}

	sub parsed_results {
		my $self = shift;
		$self->{_parsed_results};
	}
	sub x_values {
		my $self = shift;
		$self->{ _x_values };
	}
	sub y_values {
		my $self = shift;
		$self->{ _y_values };
	}
	sub data_object {
		my $self = shift;
		@_	?	$self->{ _data_object } = shift
			:	$self->{ _data_object };
	}
	sub data {
		my $self = shift;
		$self->{ _data };
	}
	sub reporters {
		my $self = shift;
		unless (defined $self->{ _reporters }){
			$self->{ _reporters } = {};
		}
		$self->{ _reporters };
	}
	sub reporter_names {
		my $self = shift;
		$self->{ _reporter_names };
	}
}

1;

__END__



=head1 NAME

Microarray::Analysis - A Perl module for analysing microarray data

=head1 SYNOPSIS

	use Microarray::Analysis;

	my $oData_File = data_file->new($data_file);
	my $oCGH = analysis->new($oData_File);

=head1 DESCRIPTION

Microarray::Analysis is an object-oriented Perl module for analysing microarray data from a scan data file.    

=head1 METHODS

To be added

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::File|Microarray::File>, L<Microarray::File::Data_File|Microarray::File::Data_File>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

