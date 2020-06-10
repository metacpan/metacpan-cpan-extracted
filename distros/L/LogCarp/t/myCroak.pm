package myCroak;

use CGI::LogCarp;

sub check
{
    warn "a WARN in check";
    croak "a CROAK";
    warn "a WARN after in check";
    1;
}

1;
