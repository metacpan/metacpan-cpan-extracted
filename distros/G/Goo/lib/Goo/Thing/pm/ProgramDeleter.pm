#!/usr/bin/perl
package Goo::Thing::pm::ProgramDeleter;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename:		ProgramDeleter.pm
# Description: 	Add stuff to a program
#
# Date	 		Change
# ----------------------------------------------------------------------------
# 01/08/2005	Factored out of ProgramEditor as part of the new Goo
# 11/08/2005    Added method: testIt                                          
#
##############################################################################

use strict;

use Goo::Object;
use Goo::Loader;
use Goo::Prompter;
use Goo::FileDeleter;
use Goo::Thing::pm::PerlCoder;
use Goo::Thing::pm::ProgramProfiler;

use base qw(Object);


###############################################################################
#
# delete_package - delete a specific package
#
###############################################################################

sub delete_package { 

	my ($this, $filename, $package) = @_;

	if (Goo::Prompter::confirm("Delete $package from this program?")) {
		my $pc = Goo::Thing::pm::PerlCoder->new( { filename => $filename } );
		$pc->delete_package($package); 
		$pc->save(); 
	}
	
	# delete the actual package as well?
}


###############################################################################
#
# delete_method - delete a specific method
#
###############################################################################

sub delete_method { 

	my ($this, $filename, $method) = @_;

	if (Goo::Prompter::confirm("Delete method $method?")) {
		my $pc = Goo::Thing::pm::PerlCoder->new( { filename => $filename } );
		$pc->delete_method($method); 
		$pc->save(); 
	} 

	# delete in backlinks too?

}


###############################################################################
#
# run - keep adding a thing to the program
#
###############################################################################

sub run { 

	my ($this, $thing, $option) = @_; 
	
	unless ($option) {
		$option = Goo::Prompter::ask_for_key("Delete?");
	}

	my $profile = Goo::Thing::pm::ProgramProfiler->new($thing);
	$profile->generate_profile($thing);
	my $option  = $profile->get_option($option);

	if ($option->isa("Goo::Thing::pm::PackageProfileOption")) { 
		$this->delete_package($thing->get_filename(), $option->{text});
		# delete the actual package?
		return;
	
	} elsif ($option->isa("Goo::Thing::pm::MethodProfileOption")) { 
		$this->delete_method($thing->get_filename(), $option->{text});	
		# delete backlinks to this method?
		return;

	} elsif ($option->isa("Goo::ThingProfileOption")) { 
	
		# use the file delete to delete this
		my $new_thing = Goo::Loader::load($option->{text});
		my $deleter = Goo::FileDeleter->new();
		$deleter->run($new_thing);
		return;
	}

} 

1;


__END__

=head1 NAME

Goo::Thing::pm::ProgramDeleter - Delete stuff from a program

=head1 SYNOPSIS

use Goo::Thing::pm::ProgramDeleter;

=head1 DESCRIPTION

WARNING: Use with care. This needs to delegate correctly to either a Perl6Deleter or a Perl5Deleter.

=head1 METHODS

=over

=item delete_package

delete a specific package

=item delete_method

delete a specific method

=item run

keep adding a thing to the program


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

