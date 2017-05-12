package Linux::DVB::DVBT::Apps::QuartzPVR::Config::PHP::Install ;
	
=head1 NAME

PHP::Install - Location of installed PHP application

=head1 SYNOPSIS

use PHP ;

=head1 DESCRIPTION

Simply contains the full path to this PHP application

=head1 AUTHOR

Steve Price 

=head1 BUGS

None that I know of!

=head1 INTERFACE


=cut

use strict ;

#============================================================================================
require Exporter ;
our @ISA = qw(Exporter);
our @EXPORT =qw(

	$PHP_APP_PATH
	
);


#============================================================================================
# GLOBALS
#============================================================================================
our $VERSION = '1.000' ;


our $PHP_APP_PATH = '%PVR_ROOT%' ;



# ============================================================================================
# END OF PACKAGE
1;

__END__



