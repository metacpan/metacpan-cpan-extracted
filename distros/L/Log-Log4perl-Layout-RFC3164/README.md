# Log::Log4perl::Layout::RFC3164

Layout in RFC3164 format

# VERSION

Version 0.01

# SYNOPSIS

    use Log::Log4perl::Layout::RFC3164;
    my $layout = Log::Log4perl::Layout::RFC3164->new();

This format is useful with the Log::Dispatch::Syslog class.
Add this to your configuration file:

    log4perl.appender.A1=Log::Dispatch::Syslog
    log4perl.appender.A1.Filter=RangeAll
    log4perl.appender.A3.ident=bandsman
    log4perl.appender.A3.layout=Log::Log4perl::Layout::RFC3164

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Not tested that much yet.

# SEE ALSO

[Log::Log4perl](https://metacpan.org/pod/Log::Log4perl)
[Log::Dispatch::Syslog](https://metacpan.org/pod/Log::Dispatch::Syslog)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log-Log4perl-Layout-RFC3164

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-Layout-RFC3164](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-Layout-RFC3164)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Log-Log4perl-Layout-RFC3164](http://annocpan.org/dist/Log-Log4perl-Layout-RFC3164)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Log-Log4perl-Layout-RFC3164](http://cpanratings.perl.org/d/Log-Log4perl-Layout-RFC3164)

- Search CPAN

    [http://search.cpan.org/dist/Log-Log4perl-Layout-RFC3164/](http://search.cpan.org/dist/Log-Log4perl-Layout-RFC3164/)

# LICENSE AND COPYRIGHT

Copyright 2017 Nigel Horne.

This program is released under the following licence: GPL2
