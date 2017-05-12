package Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object - base object to derive TVGuide objects from

=head1 SYNOPSIS

use Linux::DVB::DVBT::Apps::QuartzPVR::Schedule ;


=head1 DESCRIPTION


=head1 DIAGNOSTICS

Setting the debug flag to level 1 prints out (to STDOUT) some debug messages, setting it to level 2 prints out more verbose messages.

=head1 AUTHOR

Steve Price 

=head1 BUGS

None that I know of!

=head1 INTERFACE

=over 4

=cut

use strict ;
use Carp ;

use Data::Dumper ;

our $VERSION = "1.000" ;

#============================================================================================
# USES
#============================================================================================
use App::Framework::Base::Object::ErrorHandle ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Base::Object::ErrorHandle) ; 

#============================================================================================
# GLOBALS
#============================================================================================

my %FIELDS = (
	'app'		=> undef,
) ;


#============================================================================================
# CONSTRUCTOR 
#============================================================================================

=item C<new([%args])>

Create a new object.

The %args are specified as they would be in the B<set> method, for example:

	'mmap_handler' => $mmap_handler

The full list of possible arguments are :

	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args) ;
	
	## Map prt_data
	*prt_data = sub { 
		my $this = shift; 
		if ($this->app)
		{
			$this->app->prt_data(@_) ; 
		}
		else
		{
			print Data::Dumper->Dump([@_]) ;
		}
	} ;



	return($this) ;
}



#============================================================================================
# CLASS METHODS 
#============================================================================================

#-----------------------------------------------------------------------------

=item C<init_class([%args])>

Initialises the Cwrsync object class variables. Creates a class instance so that these
methods can also be called via the class (don't need a specific instance)

=cut

sub init_class
{
	my $class = shift ;
	my (%args) = @_ ;

	if (! keys %args)
	{
		%args = () ;
	}
	
	# Add extra fields
	$class->add_fields(\%FIELDS, \%args) ;

	# init class
	$class->SUPER::init_class(%args) ;

	# Create a class instance object - allows these methods to be called via class
	$class->class_instance(%args) ;
	
}

#============================================================================================
# OBJECT DATA METHODS 
#============================================================================================



#============================================================================================
# OBJECT METHODS 
#============================================================================================



#============================================================================================
# DEBUG
#============================================================================================
#


# ============================================================================================
# END OF PACKAGE
1;

__END__


