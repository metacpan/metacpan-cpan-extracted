# NAME

[![Build Status](https://travis-ci.org/binary-com/perl-Locale-Maketext-Test.svg?branch=master)](https://travis-ci.org/binary-com/perl-Locale-Maketext-Test)
[![codecov](https://codecov.io/gh/binary-com/perl-Locale-Maketext-Test/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Locale-Maketext-Test)

Locale::Maketext::Test

# VERSION

Version 0.04

# SYNOPSIS

    use Locale::Maketext::Test;

    my $foo = Locale::Maketext::Test->new(directory => '/tmp/locales'); # it will look for files like id.po, ru.po

    ### optional parameters
    # languages => ['en', 'de'] - to test specific languages in directory, else it will pick all po files in directory
    # ideally these languages should be as per https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes format
    # debug     => 1 - if you want to check warnings add debug flag else it will output errors only
    # auto      => 1 set only when you want to fallback in case a key is missing from lexicons

    # start test
    my $response = $foo->testlocales();

    # no errors or warnings if
    $response->{status} eq 1;

    # something is wrong when
    $response->{status} eq 0;

    # check for errors and warnings in case status is 0
    $response->{errors} = {id => [error1, error2], ru => [error1, error2]};
    # warnings are only present when debug is set to 1
    $response->{warnings} = {id => [warn1, warn2], ru => [warn1, warn2]};

# DESCRIPTION

This reads all message ids from the specified PO files and tries to
translate them into the destination language. PO files can be specified either
as file name (extension .po) or by providing the language. In the latter case
the PO file is found in the directory given by the directory option.

## TYPES OF ERRORS FOUND

### unknown %func() calls

Translations can contain function calls in the form of %func(parameters).
These functions must be defined in our code. Sometimes translators try
to translate the function name which then calls an undefined function.

### incorrect number of %plural() parameters

Different languages have different numbers of plural forms.
Some, like Malay, don't have any plural forms. Some, like English or French,
have just 2 forms, singular and one plural. Others like Arabic or Russian have
more forms. Whenever a translator uses the %plural() function, he must specify
the correct number of plural forms as parameters.

### incorrect usage of %d in %plural() parameters

In some languages, like English or German, singular is applicable only to the
quantity of 1. That means the German translator could come up for instance
with the following valid %plural call:

    %plural(%5,ein Stein,%d Steine)

In other languages, like French or Russian, this would be an error. French uses
singular also for 0 quantities. So, if the French translator calls:

    %plural(%5,une porte,%d portes)

and in the actual call the quantity of 0 is passed the output is still "une porte".
In Russian the problem is even more critical because singular is used for instance
also for the quantity of 121.

Thus, this test checks if a) the target language is similar to English in having only
2 plural forms, singular and one plural, and in applying singular only to the quantity
of 1. If both of these conditions are met %plural calls like the above are allowed.
Otherwise, if at least one of the parameters passed to %plural contains a %d,
all of the parameters must contain the %d as well.

That means the following 2 %plural calls are allowed in Russian:

    %plural(%3,%d книга,%d книги,%d книг)
    %3 %plural(%3,книга,книги,книг)

while this is forbidden:

    %plural(%3,одна книга,%d книги,%d книг)

# SUBROUTINES/METHODS

## debug

set this if you need to check warnings along with errors

## directory

directory where locales files are located

## languages

language array, set this if you want to test specific language only in specified directory

## auto

flag to fallback when a key is missing from lexicons

    # if this is not set then maketext will output errors if
    # translations is marked as fuzzy or is missing
    # read more about it here https://metacpan.org/pod/Locale::Maketext::Lexicon
    Locale::Maketext::Lexicon->import({ _auto => 1 })

## BUILD

## testlocales

test po files in directory specified

This returns hash with status, errors and warnings

    {
        status   => 1/0, # 1 is success, 0 failure
        errors   => { id => [error1, error2], ru => [error1, error2] },
        warnings => { id => [warn1, warn2] }
    }

# INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

# AUTHOR

Binary.com, `<binary at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-locale-maketext-test at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-Maketext-Test](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-Maketext-Test).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::Maketext::Test

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Maketext-Test](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Maketext-Test)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Locale-Maketext-Test](http://annocpan.org/dist/Locale-Maketext-Test)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Locale-Maketext-Test](http://cpanratings.perl.org/d/Locale-Maketext-Test)

- Search CPAN

    [http://search.cpan.org/dist/Locale-Maketext-Test/](http://search.cpan.org/dist/Locale-Maketext-Test/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2016 Binary.com.

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
