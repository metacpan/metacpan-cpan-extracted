# NAME

Locale::CA - two letter codes for province identification in Canada and vice versa

# VERSION

Version 0.09

# SYNOPSIS

    use Locale::CA;

    my $u = Locale::CA->new();

    # Returns the French names of the provinces if $LANG starts with 'fr' or
    #   the lang parameter is set to 'fr'
    print $u->{code2province}{'ON'}, "\n";      # prints ONTARIO
    print $u->{province2code}{'ONTARIO'}, "\n"; # prints ON

    my @province = $u->all_province_names();
    my @code = $u->all_province_codes();

# SUBROUTINES/METHODS

## new

Creates a Locale::CA object.

Can be called both as a class method (Locale::CA->new()) and as an object method ($object->new()).

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

- Search CPAN

    [http://search.cpan.org/dist/Locale-CA/](http://search.cpan.org/dist/Locale-CA/)

# ACKNOWLEDGEMENTS

Based on [Locale::US](https://metacpan.org/pod/Locale%3A%3AUS) - Copyright (c) 2002 - `$present` Terrence Brannon.

# LICENSE AND COPYRIGHT

Copyright 2012-2026 Nigel Horne.

This program is released under the following licence: GPL2
