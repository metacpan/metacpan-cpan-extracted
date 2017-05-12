package Goo::DatabaseThing::Deleter;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::DatabaseThing::Deleter.pm
# Description:  Delete a row from a table
#
# Date          Change
# -----------------------------------------------------------------------------
# 16/10/2005    Auto generated file
# 16/10/2005    Need to create a Table
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Prompter;
use base qw(Goo::Object);


###############################################################################
#
# run - edit a task
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    # grab the task
    my $dbo = $thing->get_database_object();

    if (Goo::Prompter::confirm("Delete " . $thing->get_filename())) {

        $dbo->delete();

		# need to go somewhere else now - back to the Zone
		$thing->do_action("Z");	
		
    }

}

1;


__END__

=head1 NAME

Goo::DatabaseThing::Deleter - Delete a row from a database table

=head1 SYNOPSIS

use Goo::DatabaseThing::Deleter;

=head1 DESCRIPTION

=head1 METHODS

=over

=item run

edit a task


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

