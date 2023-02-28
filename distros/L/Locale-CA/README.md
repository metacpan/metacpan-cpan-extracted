[![Linux Build Status](https://travis-ci.org/nigelhorne/Locale-CA.svg?branch=master)](https://travis-ci.org/nigelhorne/Locale-CA)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/78biwdwbpo72j6cq?svg=true)](https://ci.appveyor.com/project/nigelhorne/locale-ca)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/Locale-CA/badge)](https://dependencyci.com/github/nigelhorne/Locale-CA)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/Locale-CA/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Locale-CA?branch=master)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/6535371310181089/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/6535371310181089/heads/master/)

# NAME

Locale::CA - two letter codes for province identification in Canada and vice versa

# VERSION

Version 0.05

# SYNOPSIS

    use Locale::CA;

    my $u = Locale::CA->new();

    # Returns the French names of the provinces if $LANG starts with 'fr' or
    #   the lang parameter is set to 'fr'
    my $province = $u->{code2province}{$code};
    my $code  = $u->{province2code}{$province};

    my @province = $u->all_province_names;
    my @code  = $u->all_province_codes;

# SUBROUTINES/METHODS

## new

Creates a Locale::CA object.

## all\_province\_codes

Returns an array (not arrayref) of all province codes in alphabetical form.

## all\_province\_names

Returns an array (not arrayref) of all province names in alphabetical form

## $self->{code2province}

This is a hashref which has two-letter province names as the key and the long
name as the value.

## $self->{province2code}

This is a hashref which has the long name as the key and the two-letter
province name as the value.

# SEE ALSO

[Locale::Country](https://metacpan.org/pod/Locale%3A%3ACountry)

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

- The province name is returned in `uc()` format.
- neither hash is strict, though they should be.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::CA

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-CA](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-CA)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Locale-CA](http://cpanratings.perl.org/d/Locale-CA)

- Search CPAN

    [http://search.cpan.org/dist/Locale-CA/](http://search.cpan.org/dist/Locale-CA/)

# ACKNOWLEDGEMENTS

Based on [Locale::US](https://metacpan.org/pod/Locale%3A%3AUS) - Copyright (c) 2002 - `$present` Terrence Brannon.

# LICENSE AND COPYRIGHT

Copyright 2012-2023 Nigel Horne.

This program is released under the following licence: GPL2
