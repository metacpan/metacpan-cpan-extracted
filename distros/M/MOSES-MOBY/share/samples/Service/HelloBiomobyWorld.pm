
#-----------------------------------------------------------------
# Service name: HelloBiomobyWorld
# Authority:    samples.jmoby.net
# Created:      14-Oct-2006 14:42:51 BST
# Contact:      martin.senger@gmail.com
# Description:  This is a cult service, known to an exclusive group of persons sharing an esoteric interest. One of their
#	believes is that a word started on January, 1 1970.
#	
#-----------------------------------------------------------------

package Service::HelloBiomobyWorld;

use FindBin qw( $Bin );
use lib $Bin;

#-----------------------------------------------------------------
# This is a mandatory section - but you can still choose one of
# the two options (keep one and commented out the other):
#-----------------------------------------------------------------
use MOSES::MOBY::Base;
# --- (1) this option loads dynamically everything
BEGIN {
    use MOSES::MOBY::Generators::GenServices;
    new MOSES::MOBY::Generators::GenServices->load
	(authority     => 'samples.jmoby.net',
	 service_names => ['HelloBiomobyWorld']);
}

# --- (2) this option uses pre-generated module
#  You can generate the module by calling a script:
#    cd jMoby/src/Perl
#    ../scripts/generate-services.pl -b samples.jmoby.net HelloBiomobyWorld
#  then comment out the whole option above, and uncomment
#  the following line (and make sure that Perl can find it):
#use net::jmoby::samples::HelloBiomobyWorldBase;

# (this to stay here with any of the options above)
use vars qw( @ISA );
@ISA = qw( net::jmoby::samples::HelloBiomobyWorldBase );
use MOSES::MOBY::Package;
use MOSES::MOBY::ServiceException;
use strict;

#-----------------------------------------------------------------
# process_it
#    This method is called for every job in the client request.
#    Input data are in $request, this method creates a response
#    into $response. The $context tells about all other jobs
#    from the same request, and it can be used to fill there
#    exceptions and service notes.
#-----------------------------------------------------------------
sub process_it {
    my ($self, $request, $response, $context) = @_;

    # fill the response:

    # this is the long way...
#    my $greeting = new MOSES::MOBY::Data::String
#        (
#         value => "Hello, BioMoby!",
#         );
#    $response->greeting ($greeting);

    # ...but for basic data types, you can use a shortcut:
    $response->greeting ("Hello, BioMoby!");

    # fill service notes (if you wish)
    $context->serviceNotes
       ('Response created at ' . gmtime() . ' (GMT), by the service \'HelloBiomobyWorld\'.');
}

1;
__END__

=head1 NAME

Service::HelloBiomobyWorld - a BioMoby service

=head1 SYNOPSIS

=head1 DESCRIPTION

This is a cult service, known to an exclusive group of persons sharing an esoteric interest. One of their
believes is that a word started on January, 1 1970.


=head1 CONTACT

B<Authority>: samples.jmoby.net

B<Email>: martin.senger@gmail.com

=cut
