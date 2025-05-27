# NAME

Lingua::Text - Class to contain text many different languages

# VERSION

Version 0.07

# SYNOPSIS

Hold many texts in one object,
thereby encapsulating internationalized text.

    use Lingua::Text;

    my $str = Lingua::Text->new();

    $str->fr('Bonjour Tout le Monde');
    $str->en('Hello, World');

    $ENV{'LANG'} = 'en_GB';
    print "$str\n";     # Prints Hello, World
    $ENV{'LANG'} = 'fr_FR';
    print "$str\n";     # Prints Bonjour Tout le Monde
    $ENV{'LANG'} = 'de_DE';
    print "$str\n";     # Prints nothing

    my $text = Lingua::Text->new('hello');      # Initialises the 'current' language

# METHODS

## new

Create a Lingua::Text object.

    use Lingua::Text;

    my $str = Lingua::Text->new({ 'en' => 'Here', 'fr' => 'Ici' });

Accepts various input formats, e.g. HASH or reference to a HASH.
Clones existing objects with or without modifications.
Uses Carp::carp to log warnings for incorrect usage or potential mistakes.

## set

Sets a text in a language.

    $str->set({ text => 'House', lang => 'en' });

Autoload will do this for you as

    $str->en('House');

## as\_string

Returns the text in the language requested in the parameter.
If that parameter is not given, the system language is used.

    my $text = Lingua::Text->new(en => 'boat', fr => 'bateau');
    print $text->as_string(), "\n";
    print $text->as_string('fr'), "\n";
    print $text->as_string({ lang => 'en' }), "\n";

## encode

Turns the encapsulated texts into HTML entities

    my $text = Lingua::Text->new(en => 'study', fr => 'étude')->encode();
    print $text->fr(), "\n";    # Prints &eacute;tude

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

There's no decode() (yet) so you'll have to be extra careful to avoid
double encoding.

# SEE ALSO

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Text

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Lingua-Text](https://metacpan.org/release/Lingua-Text)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Text](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Text)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Lingua-Text](http://cpants.cpanauthors.org/dist/Lingua-Text)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Lingua-Text](http://matrix.cpantesters.org/?dist=Lingua-Text)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Lingua-Text](http://deps.cpantesters.org/?module=Lingua-Text)

# LICENCE AND COPYRIGHT

Copyright 2021-2025 Nigel Horne.

This program is released under the following licence: GPL2 for personal use on
a single computer.
All other users (for example Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at \`&lt;njh at nigelhorne.com>\`.
