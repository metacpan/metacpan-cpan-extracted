package Goo::Thing::pm::ProgramCloner;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename:		Goo::Thing::pm::ProgramCloner.pm
# Description: 	Clone a program and generate a test stub
#
# Date	 		Change
# -----------------------------------------------------------------------------
# 10/02/2005	Clone a program
#
###############################################################################

use strict;

use Goo::Date;
use Goo::Object;
use Goo::Prompter;
use Goo::Template;
use Goo::WebDBLite;
use Goo::FileUtilities;
use Goo::Thing::tpm::TestMaker;

our @ISA = ("Goo::Object");

# default to Perl templates - but can be overridden later (e.g., Javascript, Ruby etc)
# page output regions 
my $header_template = "perl-header.tpl";


###############################################################################
#
# new - set all the values required
#
###############################################################################

sub new {

	my ($class, $params) = @_;

	my $this = $class->SUPER::new();
	
	if (-e $params->{to}) {
		exit unless Goo::Prompter::confirm("The file $params->{to} already exists. Continue cloning?"); 
	}

	$this->{to} 	  	= $params->{to};
	$this->{from} 	  	= $params->{from};
	
	$this->{to_filename} 	= $params->{to};
	$this->{from_filename} 	= $params->{from};
	
	# set in the header template
	$this->{filename}	= $params->{to};
	
	# strip suffixes
	$params->{to} 	  	=~ s/\..*$//;
	$params->{from}   	=~ s/\..*$//;
	
	# store the name without the suffix
	$this->{to_name}	= $params->{to};
	$this->{from_name}	= $params->{from};
			
	# start The GOO!
        Goo::Prompter::say("");
        Goo::Prompter::yell("The GOO - Clone from $this->{from} to $this->{to}");	# title bar
        Goo::Prompter::say("");
	
	return $this;
	
}


###############################################################################
#
# generate_header - set all the values required in the header of the program
#
###############################################################################

sub generate_header {

	my ($this, $template) = @_;
	
	# grab the description of the module
        $this->{description} = ucfirst(Goo::Prompter::ask("Enter a description of $this->{to_name}?"));
        $this->{reason}      = ucfirst(Goo::Prompter::ask("Enter a reason for creating $this->{to_name}?"));
        $this->{date} 	  = Goo::Date::get_current_date_with_slashes();
	$this->{year} 	  = Goo::Date::get_current_year();

	# override the default, if need be
	$template = $template || $header_template;
	
	# pop on the new header - now clone the rest
	$this->{header} .= Goo::Template::replace_tokens_in_string(Goo::WebDBLite::get_template($template), $this);
	
}


###############################################################################
#
# clone_body - clone everything except the header
#
###############################################################################

sub clone_body {

	my ($this) = @_;

	my $body = Goo::FileUtilities::get_file_as_string($this->{from_filename});
	
	# stip the header up to use strict;
	$body =~ s/.*use strict;/use strict;/s;
	
	$this->{body} = $body;
	
}
	

###############################################################################
#
# save - create the program output file
#
###############################################################################

sub save {

	my ($this) = @_;
	
	my $template = Goo::WebDBLite::get_template("clonemodule.tpl");
	
	Goo::FileUtilities::write_file($this->{to},
				 Goo::Template::replace_tokens_in_string($template, $this));

	Prompter::yell("Program cloned as: $this->{to}.");
	
}


###############################################################################
#
# generate - create the output file
#
###############################################################################

sub generate {

	my ($this) = @_;
	
	$this->generate_header();
	$this->clone_body();
	
	Goo::Prompter::yell("Generated a clone $this->{to_name} of $this->{from_name}.");
	
	exit unless Goo::Prompter::confirm("Save the $this->{to_name} module?");
	
	$this->save();
	
	exit unless Goo::Prompter::confirm("Create unit test?");

        my $tm = Goo::Thing::tpm::TestMaker->new($this->{to_filename});
        $tm->create_test_for_module();
        Goo::Prompter::yell("Created unit test: $tm->{testfilename}");
		
	
}


1;


__END__

=head1 NAME

Goo::Thing::pm::ProgramCloner - Clone a program and generate a test stub

=head1 SYNOPSIS

use Goo::Thing::pm::ProgramCloner;

=head1 DESCRIPTION



=head1 METHODS

=over

=item new

constructor

=item generate_header

set all the values required in the header of the program

=item clone_body

clone everything except the header

=item save

create the program output file

=item generate

create the output file


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

