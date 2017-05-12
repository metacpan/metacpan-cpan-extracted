package LIMS::Base;

use 5.006;

our $VERSION = '1.3';

{ package lims;

	sub new {
		my $class = shift;
		my $self = { _page_title => shift };
		bless $self, $class;
		$self->start_cgi;
		$self->load_dbi;
		if ($self->check_login){
			return $self;
		} else {
			return undef;
		}
	}
	sub new_guest {
		my $class = shift;
		my $self = { _page_title => shift };
		bless $self, $class;
		$self->load_dbi;
		return $self;
	}
	sub new_script {
		my $class = shift;
		my $self = { _name => 'script' };
		bless $self, $class;
		return $self;
	}
	# special constructor for test scripts
	# finds LIMS_Test.pm from test script and loads the test config file 
	sub new_test {
		my $class = shift;
		my $config = shift;
		my $self = { _page_title => 'trl_test',
					_config_file_path => $config };
		bless $self, 'trl_test';
		$self->set_isa($class);	
		$self->load_dbi;
		return $self;
	}
	sub DESTROY {
		my $self = shift;
	}
	sub get_error_string {
		my $self = shift;
		my $errors = "";
		ERROR:while (my $aErrors = shift){
			next ERROR unless (@$aErrors);
			for my $error (@$aErrors){
				$errors .= $error."\n";
			}
		}
		return $errors;
	}
	sub standard_error {
		my $self = shift;
		if (@_){
			my @aErrors = @_;
			if (defined $self->{ _standard_error }){
				my $aErrors = $self->{ _standard_error };
				push (@$aErrors, @aErrors);
			} else {
				$self->{ _standard_error } = \@aErrors;
			}
		} else {
			$self->{ _standard_error };
		}
	}
	sub text_errors {
		my $self = shift;
		return $self->get_error_string($self->standard_error);
	}
	sub any_error {
		my $self = shift;
		if ($self->standard_error){
			return 1;
		} else {
			return;
		}
	}
	sub print_standard_errors {
		my $self = shift;
		return unless (my $aErrors = $self->standard_error);
		print $self->get_error_string($aErrors);	
	}
	sub print_errors {
		my $self = shift;
		$self->print_standard_errors;
	}
	sub clear_standard_errors {
		my $self = shift;
		$self->{ _standard_error } = [];
	}
	sub clear_all_errors {
		my $self = shift;
		$self->clear_standard_errors;
	}
	sub kill_pipeline {
		my $self = shift;
		if (@_){
			$self->standard_error(@_);
		}
		$self->print_errors;
		$self->DESTROY;
		exit;
	}
	sub load_config {
		use Config::IniFiles;
		my $self = shift;
		my $config_obj = new Config::IniFiles( -file => $self->config_file_path )
			or die "LIMS::Base ERROR: Could not import the config file;\n".$self->config_file_path."\n";
		$self->{ _config_obj } = $config_obj;	
	}
	sub config_obj {
		my $self = shift;
		unless (defined $self->{ _config_obj }){
			$self->load_config;
		}
		$self->{ _config_obj };
	}
	sub config_param {
		my $self = shift;
		my $config_obj = $self->config_obj;
		return $config_obj->val(shift,shift);
	}
	sub config_all_params {
		my $self = shift;
		my $config_obj = $self->config_obj;
		return $config_obj->Parameters(shift);
	}
	sub config_all_sections {
		my $self = shift;
		my $config_obj = $self->config_obj;
		return $config_obj->Sections;
	}



}

1;

__END__


=head1 NAME

LIMS::Base - Base class describing a LIMS

=head1 DESCRIPTION

LIMS::Base is the base class for the LIMS suite of object oriented Perl modules. See L<LIMS::Controller|LIMS::Controller> for information about setting up and using the LIMS modules. 

=head1 SEE ALSO

L<LIMS::Controller|LIMS::Controller>, L<LIMS::Web::Interface|LIMS::Web::Interface>, L<LIMS::Database::Util|LIMS::Database::Util>

=head1 AUTHORS

Christopher Jones and James Morris, Translational Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/trl>

c.jones@ucl.ac.uk, james.morris@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Christopher Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
