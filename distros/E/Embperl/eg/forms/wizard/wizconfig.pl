

use File::Basename ;
use Embperl::MyForm ;

# -------------------------------------------------------
#
# getpages returns the pages to use
#

sub getpages

    {
        [
        'action.epl'  ,
        'importslave.epl',
        'organisation.epl',
        'name.epl' ,
        'network.epl' ,
        'inetconnect.epl' ,
        'isdn.epl' ,
        'dsl.epl' ,
        'gateway.epl' ,
        'exportslave.epl',
        'finish.epl',
        'do.epl'
        ] ;
    }

# -------------------------------------------------------
#
# aborturl defines the url to requested when abort is clicked
#

sub aborturl
	{
	return '/' ;	
	}


# -------------------------------------------------------
#
# app_isa allows one to define a base class for the wizard application object
#

sub app_isa
	{
	''
	}



# -------------------------------------------------------
#
# init is called at the start of each request
# 

sub init
    {
    my ($self, $wiz, $r) = @_ ;
    
    
    }
    
