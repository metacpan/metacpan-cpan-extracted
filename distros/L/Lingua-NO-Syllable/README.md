# NAME

Lingua::NO::Syllable - Count the number of syllables in Norwegian words.

# VERSION

Version 0.06.

# SYNOPSIS

    use Lingua::NO::Syllable;

    my $count = syllables( 'Tyrannosaurus' ); # 5, because:
                                              # Tyr-ann-o-sau-rus

# DESCRIPTION

`Lingua::NO::Syllable::syllables($word)` estimates the number of syllables in
the `$word` passed to it. It's an estimate, because the algorithm is quick
and dirty, non-alpha characters aren't considered etc. Don't expect this
module to give you a 100% correct answer.

As the Norwegian and the Danish languages are quite similar, at least written,
this module might work for the Danish language as well.

# ACCENTED CHARACTERS

Accented characters, like é, à etc., are normalized (using [Unicode::Normalize](https://metacpan.org/pod/Unicode::Normalize))
before the number of syllables are counted.

# SEE ALSO

- [Lingua::EN::Syllable](https://metacpan.org/pod/Lingua::EN::Syllable)

# AUTHOR

Tore Aursand, `<toreau at gmail.com>`

# BUGS

Please report any bugs or feature requests to the web interface at [https://rt.cpan.org/Dist/Display.html?Name=Lingua-NO-Syllable](https://rt.cpan.org/Dist/Display.html?Name=Lingua-NO-Syllable)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::NO::Syllable

You can also look for information at:

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Lingua-NO-Syllable](http://annocpan.org/dist/Lingua-NO-Syllable)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Lingua-NO-Syllable](http://cpanratings.perl.org/d/Lingua-NO-Syllable)

- Search CPAN

    [http://search.cpan.org/dist/Lingua-NO-Syllable/](http://search.cpan.org/dist/Lingua-NO-Syllable/)

# LICENSE AND COPYRIGHT

Copyright 2015-2016 Tore Aursand.

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
