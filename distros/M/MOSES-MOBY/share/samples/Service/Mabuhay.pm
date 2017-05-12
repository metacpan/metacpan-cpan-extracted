
#-----------------------------------------------------------------
# Service name: Mabuhay
# Authority:    samples.jmoby.net
# Created:      14-Oct-2006 14:42:12 BST
# Contact:      martin.senger@gmail.com
# Description:  How to say "Hello" in many languages. Heavily based on a web resource "Greetings in more than 800 languages", maintained at http://www.elite.net/~runner/jennifers/hello.htm by Jennifer Runner.
#-----------------------------------------------------------------

package Service::Mabuhay;

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
	 service_names => ['Mabuhay']);
}

# --- (2) this option uses pre-generated module
#  You can generate the module by calling a script:
#    cd jMoby/src/Perl
#    ../scripts/generate-services.pl -b samples.jmoby.net Mabuhay
#  then comment out the whole option above, and uncomment
#  the following line (and make sure that Perl can find it):
#use net::jmoby::samples::MabuhayBase;

# (this to stay here with any of the options above)
use vars qw( @ISA );
@ISA = qw( net::jmoby::samples::MabuhayBase );
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


    # read (some) input data
    # (use eval to protect against missing data)
    my $language = eval { $request->language };
    my $regex = eval { $language->regex->value };
    unless ($language and $regex) {
	$response->record_error ( { code => INPUTS_INVALID,
				    msg  => 'Input regular expression is missing.' } );
	return;
    }
    my $ignore_cases = eval { $language->case_insensitive->value };

    my @result_hellos = ();
    my @result_langs = ();
    open HELLO, $MOBYCFG::MABUHAY_RESOURCE_FILE
	or $self->throw ('Mabuhay resource file not found.');
    while (<HELLO>) {
	chomp;
	my ($lang, $hello) = split (/\t+/, $_, 2);
	if ( $ignore_cases ? 
	     $lang =~ /$regex/i :
	     $lang =~ /$regex/ ) {
	    push (@result_hellos, $hello);
	    push (@result_langs, $lang);
	}
    }
    close HELLO;

    foreach my $idx (0 .. $#result_hellos) {
	$response->add_hello (new MOSES::MOBY::Data::simple_key_value_pair
			      ( key   => $self->as_uni_string ($result_langs[$idx]),
				value => $self->as_uni_string ($result_hellos[$idx]),
				));
    }

    # fill service notes (if you wish)
    $context->serviceNotes
       ('Response created at ' . gmtime() . ' (GMT), by the service \'Mabuhay\'.');
}

1;
__END__

=head1 NAME

Service::Mabuhay - a BioMoby service

=head1 SYNOPSIS

=head1 DESCRIPTION

How to say "Hello" in many languages. Heavily based on a web resource "Greetings in more than 800 languages", maintained at http://www.elite.net/~runner/jennifers/hello.htm by Jennifer Runner.

=head1 CONTACT

B<Authority>: samples.jmoby.net

B<Email>: martin.senger@gmail.com

=cut
