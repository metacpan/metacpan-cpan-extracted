# NAME

Email::Address::Classify - Classify email addresses

# SYNOPSIS

    use Email::Address::Classify;

    $email = Email::Address::Classify->new('a.johnson@example.com');

    print "Is valid:  " . $email->is_valid() ? "Y\n" : "N\n";    # Y
    print "Is random: " . $email->is_random() ? "Y\n" : "N\n";   # N

# DESCRIPTION

This module provides a simple way to classify email addresses. At the moment, it only
provides two classifications is\_valid() and is\_random(). More classifications may be
added in the future.

# METHODS

- new($address)

    Creates a new Email::Address::Classify object. The only argument is the email address.

- is\_valid()

    Performs a simple check to determine if the address is formatted properly.
    Note that this method does not check if the domain exists or if the mailbox is valid.
    Nor is it a complete RFC 2822 validator. For that, you should use a module such as
    [Email::Address](https://metacpan.org/pod/Email%3A%3AAddress).

    If this method returns false, all other methods will return false as well.

- is\_random()

    Returns true if the localpart is likely to be randomly generated, false otherwise.
    Note that randomness is subjective and depends on the user's locale and other factors.
    This method uses a list of common trigrams to determine if the localpart is random. The trigrams
    were generated from a corpus of 30,000 email messages, mostly in English. The accuracy of this
    method is about 95% for English email addresses.

    If you would like to generate your own list of trigrams, you can use the included
    `ngrams.pl` script in the `tools` directory of the source repository.

# TODO

Ideas for future classification methods:

    is_freemail()
    is_disposable()
    is_role_based()
    is_bounce()
    is_verp()
    is_srs()
    is_batv()
    is_sms_gateway()

# AUTHOR

Kent Oyer <kent@mxguardian.net>

# LICENSE AND COPYRIGHT

Copyright (C) 2023 MXGuardian LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the LICENSE
file included with this distribution for more information.

You should have received a copy of the GNU General Public License
along with this program.  If not, see https://www.gnu.org/licenses/.
