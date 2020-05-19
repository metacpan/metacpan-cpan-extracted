# NAME

Locale::AU - abbreviations for territory and state identification in Australia and vice versa

# VERSION

Version 0.01

# SYNOPSIS

    use Locale::AU;

    my $u = Locale::AU->new();

    my $state = $u->{code2state}{$code};
    my $code  = $u->{state2code}{$state};

    my @state = $u->all_state_names;
    my @code  = $u->all_state_codes;

# SUBROUTINES/METHODS

## new

Creates a Locale::AU object.

## all\_state\_codes

Returns an array (not arrayref) of all state codes in alphabetical form.

## all\_state\_names

Returns an array (not arrayref) of all state names in alphabetical form

## $self->{code2state}

This is a hashref which has state abbreviations as the key and the long
name as the value.

## $self->{state2code}

This is a hashref which has the long name as the key and the abbreviated
state name as the value.

# SEE ALSO

[Locale::Country](https://metacpan.org/pod/Locale%3A%3ACountry)

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

- The state name is returned in `uc()` format.
- neither hash is strict, though they should be.
- Jarvis Bay Territory is not handled

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::AU

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-AU](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-AU)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Locale-AU](http://cpanratings.perl.org/d/Locale-AU)

- Search CPAN

    [http://search.cpan.org/dist/Locale-AU/](http://search.cpan.org/dist/Locale-AU/)

# ACKNOWLEDGEMENTS

Based on [Locale::US](https://metacpan.org/pod/Locale%3A%3AUS) - Copyright (c) 2002 - `$present` Terrence Brannon.

# LICENSE AND COPYRIGHT

Copyright 2020 Nigel Horne.

This program is released under the following licence: GPL2
