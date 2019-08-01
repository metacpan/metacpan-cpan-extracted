# NAME

Lib::Log4cplus - Perl interface to log via Log4cplus

# VERSION

Version 0.001

# SYNOPSIS

    use Lib::Log4cplus;

    my $logger = Lib::Log4cplus->new(config_file => "/path/to/config.properties");
    $logger->log_info("main", "Lib::Log4cplus works great!");

# DESCRIPTION

# INTERFACE

Lib::Log4cplus has some low-level XS functions (which are not exported)
and a few methods suitable for class.

# FUNCTIONS

All these functions are provided by the XS API to log4cplus.
Nothing is exported by default and it's not recommended to use any
of the functions directly.

## basic\_configure

    basic_configure(logToStdErr);

Enables a builtin basic configuration:

    rootLogger=DEBUG, STDOUT
    appender.STDOUT=log4cplus::ConsoleAppender
    appender.STDOUT.logToStdErr=0

Any currently existing configuration is not reset.

The parameter logToStdErr is ignored at the moment and will passed
at a later release of log4cplus.

See [http://log4cplus.sourceforge.net/docs/html/classlog4cplus\_1\_1BasicConfigurator.html](http://log4cplus.sourceforge.net/docs/html/classlog4cplus_1_1BasicConfigurator.html) for more details.

## file\_configure

    file_configure("/path/to/logger.properties");

Enables a configuration which is stored in a file.

Any currently existing configuration is not reset.

See [http://log4cplus.sourceforge.net/docs/html/classlog4cplus\_1\_1PropertyConfigurator.html](http://log4cplus.sourceforge.net/docs/html/classlog4cplus_1_1PropertyConfigurator.html) for more details.

## static\_configure

    my $properties = <<EOP;
    rootLogger=DEBUG, STDOUT
    appender.STDOUT=log4cplus::ConsoleAppender
    appender.STDOUT.logToStdErr=0
    EOP

    static_configure($properties);

Enables a configuration which is given by a list of properties
separated by newlines.

Any currently existing configuration is not reset.

See [http://log4cplus.sourceforge.net/docs/html/classlog4cplus\_1\_1PropertyConfigurator.html](http://log4cplus.sourceforge.net/docs/html/classlog4cplus_1_1PropertyConfigurator.html) for more details.

## logger\_exists

    say "Yes" if logger_exists("wuff");
    say "Always" if logger_exists(undef);

Tells whether the specified logger exists. The rootLogger does
always exists, even if it might not be configured.

## logger\_is\_enabled\_for

    say "Noisy" if logger_is_enabled_for(undef, 10000); # DEBUG_LOG_LEVEL
    say "Oops" unless logger_is_enabled_for("security", 30000); # WARN_LOG_LEVEL

Tells whether the specified logger will log the requested log-level. The
log-level has to be specified as an integer constant as described in the
API documentation of log4cplus. The `constant` routine allows to fetch
a bunch of log-level values predefined during configuration process.

See [http://log4cplus.sourceforge.net/docs/html/clogger\_8h.html](http://log4cplus.sourceforge.net/docs/html/clogger_8h.html) for
more details.

## logger\_log

    logger_log("access", 20000, $resource->path . " 200 OK") == 0 or die "Logger broken";

Takes a message (one string - not more, not formats) and pass it to the
assigned appenders, if log-level is turned on for the logger.

## logger\_force\_log

    logger_force_log("access", 20000, $resource->path . " 200 OK") == 0 or die "Logger broken";

Takes a message (one string - not more, not formats) and pass it to the
assigned appenders, regardless whether log-level is turned on for the
logger or not.

## constant

# AUTHOR

Jens Rehsack, `<rehsack at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-lib-log4cplus at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lib-Log4cplus](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lib-Log4cplus).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lib::Log4cplus

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lib-Log4cplus](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lib-Log4cplus)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Lib-Log4cplus](http://annocpan.org/dist/Lib-Log4cplus)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Lib-Log4cplus](http://cpanratings.perl.org/d/Lib-Log4cplus)

- Search CPAN

    [http://search.cpan.org/dist/Lib-Log4cplus/](http://search.cpan.org/dist/Lib-Log4cplus/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2018 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
