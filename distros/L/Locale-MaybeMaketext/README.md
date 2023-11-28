# NAME

Locale::MaybeMaketext - Find available localization / localisation / translation services.

# DESCRIPTION

There are, to my knowledge, three slightly different Maketext libraries available on Perl
all of which require your "translation files" to reference that individual library as a
parent/base package: which causes problems if you want to support all three. This package
addresses this issue by allowing you to just reference this package and then it will automatically
figure out which Maketext library is available on the end-users platform.

It will try each localizer in the order:

\* [Cpanel::CPAN::Locale::Maketext::Utils](https://metacpan.org/pod/Cpanel%3A%3ACPAN%3A%3ALocale%3A%3AMaketext%3A%3AUtils)

\* [Locale::Maketext::Utils](https://metacpan.org/pod/Locale%3A%3AMaketext%3A%3AUtils)

\* [Locale::Maketext](https://metacpan.org/pod/Locale%3A%3AMaketext)

# SYNOPSIS

How to use:

1\. Create a base/parent localization class which uses `Locale::MaybeMaketext` as the parent:

    # File YourProjClass/L10N.pm
    package YourProjClass::L10N;
    use parent qw/Locale::MaybeMaketext/;
    # any additional methods to share on all languages
    1;

2\. Create the individual translation files using your base/parent class as the parent:

    # File YourProjClass/L10N/en.pm
    package YourProjClass::L10N::EN;
    use parent qw/YourProjClass::L10N/;
    %Lexicon = (
       '_AUTO'=>1,
    );
    1;

3\. In your main program use:

    # File YourProjClass/Main.pl
    use parent qw/YourProjClass::L10N/;
       ...
    my $lh=YourProjClass::L10N->get_handle() || die('Unable to find language');
    print $lh->maketext("Hello [_1] thing\n",$thing);

# METHODS

The main method you need to concern yourself about is the `get_handle` method
which gets an appropriate localizer, sets it as the "parent" of the package
and then returns an appropriate `maketext` handle.

- $lh = YourProjClass->get\_handle(...langtags...) || die 'language handle?';

    This ensures an appropriate localizer/Maketext library is set as the parent
    and then tries loading classes based on the language-tags (langtags) you provide -
    and for the first class that succeeds, returns YourProjClass::_language_->new().

- $lh = YourProjClass->get\_handle() || die 'language handle?';

    This ensures an appropriate localizer/Maketext library is set as the parent
    and then asks that library to "magically" detect the most appropriate language
    for the user based on its own logic.

- $localizer = Locale::MaybeMaketext::maybe\_maketext\_get\_localizer();

    Returns the package name of the currently selected localizer/Maketext library -
    or, if one is not set, will try and pick one from the list in
    `@maybe_maketext_known_localizers` and return that. If it is unable to find
    a localizer (for example, if the user has none of the listed packages installed),
    then the `croak` error message "Unable to load localizers: "... will be emitted
    along with why/how it was unable to load each localizer.

- Locale::MaybeMaketext::maybe\_maketext\_reset();

    Removes the currently set localizer from the package. Intended for testing purposes.

- $text = $lh->maketext(_key_, ... parameters for this phrase ... );

    This is actually just a dummy function to ensure that `get_handle` is called
    before any attempt is made to translate text.

- @list = Locale::MaybeMaketext::maybe\_maketext\_get\_localizer\_list();

    Get the list of currently configured localizers. Intended for testing purposes.

- Locale::MaybeMaketext::maybe\_maketext\_set\_localizer\_list(@&lt;list of localizers>);

    Sets the list of currently configured localizers. Intended for testing purposes.

- @reason = Locale::MaybeMaketext::maybe\_maketext\_get\_reasoning()

    Returns the reasoning "why" a particular localizer was choise. Intended for debugging purposes.

## Utility Methods

Various `Maketext` libraries support different 'utility modules' which help
expand the bracket notation used in Maketext. Of course, you do not necessarily
know which localization library will be used so it is advisable to keep to the
most commonly supported utility methods.

Here is a little list of which utility modules are available under which library:

\* LM = Locale::Maketext

\* LMU = Locale::Maketext::Utils

\* CCLMU = Cpanel::CPAN::Locale::Maketext::Utils

    |-------------------------------------------|
    | Method            |  LM   |  LMU  | CCLMU |
    |-------------------|-------|-------|-------|
    | quant             |   Y   |   Y   |   Y   |
    | numf              |   Y   |   Y   |   Y   |
    | numerate          |   Y   |   Y   |   Y   |
    | sprintf           |   Y   |   Y   |   Y   |
    | language_tag      |   Y   |   Y   |   Y   |
    | encoding          |   Y   |   Y   |   Y   |
    | join              |   N   |   Y   |   Y   |
    | list_and          |   N   |   Y   |   Y   |
    | list_or           |   N   |   Y   |   Y   |
    | list_and_quoted   |   N   |   Y   |   Y   |
    | list_or_quoted    |   N   |   Y   |   Y   |
    | datetime          |   N   |   Y   |   Y   |
    | current_year      |   N   |   Y   |   Y   |
    | format_bytes      |   N   |   Y   |   Y   |
    | convert           |   N   |   Y   |   Y   |
    | boolean           |   N   |   Y   |   Y   |
    | is_defined        |   N   |   Y   |   Y   |
    | is_future         |   N   |   Y   |   Y   |
    | comment           |   N   |   Y   |   Y   |
    | asis              |   N   |   Y   |   Y   |
    | output            |   N   |   Y   |   Y   |
    |-------------------------------------------|

# AUTHORS

- Richard Bairwell <rbairwell@cpan.org>

# COPYRIGHT

Copyright 2023 Richard Bairwell <rbairwell@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. The full text
of this license can be found in the `LICENSE` file
included with this module.

See `http://dev.perl.org/licenses/`
