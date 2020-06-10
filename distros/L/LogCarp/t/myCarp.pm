package myCarp;

use CGI::LogCarp;

sub check
{
    warn "a WARN in check";
    carp "a CARP";
    warn "a WARN after in check";
    1;
}

1;
