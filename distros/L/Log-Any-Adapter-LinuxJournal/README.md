# NAME

Log::Any::Adapter::LinuxJournal - Log::Any adapter for the systemd journal on Linux

# VERSION

version 0.172762

# SYNOPSIS

```perl
use Log::Any::Adapter;
Log::Any::Adapter->set('LinuxJournal',
    # app_id => 'myscript', # default is basename($0)
);
```

# DESCRIPTION

**WARNING** This is a [Log::Any](https://metacpan.org/pod/Log::Any) adpater for _structured_ logging, which means it
is only useful with a very recent version of [Log::Any](https://metacpan.org/pod/Log::Any), at least `1.700`

It will log messages to the systemd journal via [Linux::Systemd::Journal::Write](https://metacpan.org/pod/Linux::Systemd::Journal::Write).

# SEE ALSO

[Log::Any::Adapter::Journal](https://metacpan.org/pod/Log::Any::Adapter::Journal)

# BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at [https://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal/issues](https://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal/issues).

# AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit [http://www.perl.com/CPAN/](http://www.perl.com/CPAN/) to find a CPAN
site near you, or see [https://metacpan.org/module/Log::Any::Adapter::LinuxJournal/](https://metacpan.org/module/Log::Any::Adapter::LinuxJournal/).

# SOURCE

The development version is on github at [http://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal](http://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal)
and may be cloned from [git://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal.git](git://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal.git)

# AUTHOR

Ioan Rogers <ioanr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ioan Rogers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.
