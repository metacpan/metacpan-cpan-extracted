# NAME

Log::Any::Adapter::Log4cplus - Adapter to use Lib::Log4cplus with Log::Any

# SYNOPSIS

       use Log::Any::Adapter;
    
       Log::Any::Adapter->set('Log4cplus', file => '/path/to/log.properties');
    
       my $logger = Lib::Log4cplus->new( str => $config_string );
       Log::Any::Adapter->set('Log4cplus', logger => $logger);
    

# DESCRIPTION

This [Log::Any](https://metacpan.org/pod/Log::Any) adapter uses [Lib::Log4cplus](https://metacpan.org/pod/Lib::Log4cplus) for
logging.

You may either pass parameters (like _outputs_) to be passed to
`Lib::Log4cplus->new`, or pass a `Lib::Log4cplus::Logger` object directly in the
_logger_ parameter.

# SEE ALSO

[Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter), [Log::Any](https://metacpan.org/pod/Log::Any),
[Lib::Log4cplus](https://metacpan.org/pod/Lib::Log4cplus)

# AUTHOR

Jens Rehsack, `<rehsack at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-Log-Any-Adapter-Log4cplus at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Any-Adapter-Log4cplus](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Any-Adapter-Log4cplus).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Any::Adapter::Log4cplus

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Any-Adapter-Log4cplus](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Any-Adapter-Log4cplus)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Log-Any-Adapter-Log4cplus](http://annocpan.org/dist/Log-Any-Adapter-Log4cplus)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Log-Any-Adapter-Log4cplus](http://cpanratings.perl.org/d/Log-Any-Adapter-Log4cplus)

- Search CPAN

    [http://search.cpan.org/dist/Log-Any-Adapter-Log4cplus/](http://search.cpan.org/dist/Log-Any-Adapter-Log4cplus/)

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
