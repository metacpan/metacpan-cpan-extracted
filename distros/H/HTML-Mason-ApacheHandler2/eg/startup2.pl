###################################################
#	mod_perl startup script
#	adapded by Beau E. Cox
#	December 4, 2002
#
#	file:startup.pl
###################################################

use Apache2 ();
use lib ( $ENV{MOD_PERL_INC} );

use Apache::Request ();
use Apache::Cookie ();
use CGI ();
use CGI::Cookie ();

use ModPerl::Util (); #for CORE::GLOBAL::exit

use Apache::RequestRec ();
use Apache::RequestIO ();
use Apache::RequestUtil ();

use Apache::Server ();
use Apache::ServerUtil ();
use Apache::Connection ();
use Apache::Log ();
use Apache::URI ();

use Apache::Session ();

use APR::Table ();

use ModPerl::Registry ();

use Apache::Const -compile => ':common';
use APR::Const -compile => ':common';
use ModPerl::Const -compile => ':common';

use Apache::DBI ();

use MyApache::Mason::ApacheHandler2 ();

1;
