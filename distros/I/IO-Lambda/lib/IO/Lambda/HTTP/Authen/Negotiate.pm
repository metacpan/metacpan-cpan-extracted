# $Id: Negotiate.pm,v 1.1 2008/05/09 18:59:17 dk Exp $

package IO::Lambda::HTTP::Authen::Negotiate;

use IO::Lambda::HTTP::Authen::NTLM;

use vars qw(@ISA);
@ISA = qw(IO::Lambda::HTTP::Authen::NTLM);

1;
