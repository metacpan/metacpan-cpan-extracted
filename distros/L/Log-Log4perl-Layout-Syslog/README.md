# NAME

Log::Log4perl::Layout::Syslog - Layout in Syslog format

# VERSION

Version 0.03

# SYNOPSIS

This format is useful with the Log::Dispatch::Syslog class.
Add this to your configuration file:

    log4perl.appender.A1=Log::Dispatch::Syslog
    log4perl.appender.A1.Filter=RangeAll
    log4perl.appender.A1.ident=bandsman
    log4perl.appender.A1.layout=Log::Log4perl::Layout::Syslog

Much of the actual formatting is done by the Sys::Syslog code called
from Log::Dispatch::Syslog,
however you can't use Log::Log4perl::Layout::NoopLayout
since that doesn't insert the ident data that's needed by systems such as
flutentd.

## new

    use Log::Log4perl::Layout::Syslog;
    my $layout = Log::Log4perl::Layout::Syslog->new();

## render

Render a message in the correct format.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

I can't work out how to get the ident given to
Log::Dispatch::Syslog's constructor,
so ident (facility in RFC3164 lingo) is always sent to
LOG\_USER.

# SEE ALSO

[Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl)
[Log::Dispatch::Syslog](https://metacpan.org/pod/Log%3A%3ADispatch%3A%3ASyslog)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log-Log4perl-Layout-Syslog

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-Layout-Syslog](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-Layout-Syslog)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Log-Log4perl-Layout-Syslog](http://annocpan.org/dist/Log-Log4perl-Layout-Syslog)

- Search CPAN

    [http://search.cpan.org/dist/Log-Log4perl-Layout-Syslog/](http://search.cpan.org/dist/Log-Log4perl-Layout-Syslog/)

# LICENSE AND COPYRIGHT

Copyright 2017-2014 Nigel Horne.

This program is released under the following licence: GPL2
