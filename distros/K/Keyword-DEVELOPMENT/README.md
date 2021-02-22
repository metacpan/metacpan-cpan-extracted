# NAME

Keyword::DEVELOPMENT - Have code blocks which don't exist unless you ask for them.

# VERSION

Version 0.04

# SYNOPSIS

    use Keyword::DEVELOPMENT;

    sub foo {
        my $self = shift;
        DEVELOPMENT {
            $self->expensive_debugging_code;
        }
        ...
    }

# EXPORT

## DEVELOPMENT

This module exports one keyword, `DEVELOPMENT`. This keyword takes a code
block.

If the environment variable `PERL_KEYWORD_DEVELOPMENT` is set to a true
value, the code block is executed. Otherwise, the entire block is removed at
compile-time, thus ensuring that there is no runtime overhead for the block.

This is primarily a development tool for performance-critical code.

# EXAMPLE

Consider the following code:

    #!/usr/bin/env perl

    BEGIN {
        # just in case someone turned this one
        $ENV{PERL_KEYWORD_DEVELOPMENT} = 1;
    }
    use lib 'lib';
    use Keyword::DEVELOPMENT;

    my $value = 0;
    DEVELOPMENT {
        sleep 10;
        $value = 1;
    }

    print "Our value is $value";

Running this code should print the following after about 10 seconds:

    Our value is 1

However, if you set `PERL_KEYWORD_DEVELOPMENT` to `0` in the `BEGIN` block, it prints:

    Our value is 0

To know that we really have **no** overhead during production, run the code under the debugger
with `PERL_KEYWORD_DEVELOPMENT` set to `0`.

    $ perl -d development.pl

    Loading DB routines from perl5db.pl version 1.49_04
    Editor support available.

    Enter h or 'h h' for help, or 'man perldebug' for more help.

    main::(development.pl:10):    my $value = 0;
    auto(-1)  DB<1> {{v
    DB<2> n
    main::(development.pl:10):    my $value = 0;
    auto(-1)  DB<2> v
    7:    use lib 'lib';
    8:    use Keyword::DEVELOPMENT;
    9
    10==>    my $value = 0;

    11     # PERL_KEYWORD_DEVELOPMENT was false, so the development code was removed.
    12     #KDCT:_:_:1 DEVELOPMENT
    13     #line 14 development.pl
    14
    15
    16:    print "Our value is $value";
    DB<2>

As you can see, there are only comments there, no code.

Note the handy line directive on line 13 to ensure your line numbers remain
correct. If you're not familiar with line directives, see
[https://perldoc.perl.org/perlsyn.html#Plain-Old-Comments-(Not!)](https://perldoc.perl.org/perlsyn.html#Plain-Old-Comments-\(Not!\))

# ALTERNATIVES

As SawyerX pointed out, can replicate the functionality of this module in pure
Perl, if desired:

    use constant PRODUCTION => !!$ENV{PRODUCTION};
    DEVELOPMENT {expensive_debugging_code()} unless PRODUCTION;

Versus:

    use Keyword::DEVELOPMENT;
    DEVELOPMENT {expensive_debugging_code()};

The first version works because the line is removed entirely from the source
code using constant-folding (if `PRODUCTION` evaluates to false during
compile time, the entire line will be omitted).

I think `Keyword::DEVELOPMENT` is less fragile in that you never need to
remember the `unless PRODUCTION` statement modifier. However, we do rely on
the pluggable keyword functionality introduced in 5.012. Be warned!

# AUTHOR

Curtis "Ovid" Poe, `<ovid at allaroundtheworld.fr>`

# BUGS AND LIMITATIONS

Please report any bugs or feature requests to `bug-keyword-assert at
rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Keyword-DEVELOPMENT](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Keyword-DEVELOPMENT).  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Keyword::DEVELOPMENT

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Keyword-DEVELOPMENT](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Keyword-DEVELOPMENT)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Keyword-DEVELOPMENT](http://annocpan.org/dist/Keyword-DEVELOPMENT)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Keyword-DEVELOPMENT](http://cpanratings.perl.org/d/Keyword-DEVELOPMENT)

- Search CPAN

    [http://search.cpan.org/dist/Keyword-DEVELOPMENT/](http://search.cpan.org/dist/Keyword-DEVELOPMENT/)

# ACKNOWLEDGEMENTS

Thanks to Damian Conway for the excellent `Keyword::Declare` module.

# LICENSE AND COPYRIGHT

Copyright 2017 Curtis "Ovid" Poe.

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
