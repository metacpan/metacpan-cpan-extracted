# $Id: cern.pm,v 1.1.1.1 1997/12/11 21:47:37 lstein Exp $

package HTTPD::UserAdmin::Text::cern;
@ISA = qw(HTTPD::UserAdmin::Text);
$VERSION = (qw$Revision: 1.1.1.1 $)[1];

#tweedle dee, tweedle dumb
sub new {
    my($class) = shift;
    HTTPD::UserAdmin::Text::new($class, DLM => ":", @_);
}


1;
