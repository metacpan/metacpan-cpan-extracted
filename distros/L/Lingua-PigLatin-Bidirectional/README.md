# NAME

Lingua::PigLatin::Bidirectional - Translates English sentences to Pig Latin, and vice versa.

# SYNOPSIS

    use Lingua::PigLatin::Bidirectional;

    warn to_piglatin('hello');     # ellohay
    warn from_piglatin('ellohay'); # hello

# DESCRIPTION

Lingua::PigLatin::Bidirectional translates to and from Pig Latin. This module
is originally inspired by Lingua::PigLatin, but this also handles 
re-translation from Pig Latin, hense the name.

Additionally, it cares case sensitivity.

# METHODS

- to\_piglatin

    Returns a Pig-Latinized sentence.

- from\_piglatin

    Re-Translate a Pig-Latinized sentence and returns plain English sentence.

# LICENSE

Copyright (C) Oklahomer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Oklahomer <hagiwara.go@gmail.com>
