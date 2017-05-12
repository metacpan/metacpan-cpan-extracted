# NAME

Log::Tree - Lightyweight logging w/ a tree based verbosity configuration
similar to Log4perl.

# SYNOPSIS

    use Log::Tree;

    my $logger = Log::Tree::->new('foo');
    ...

Only mandatory attirbute. Used as the syslog faclity and to auto-construct a suiteable
filename for logging to file.

This method is usually not needed from by callers but may be in some rare ocasions
that's why it's made part of the public API. It just adds the passed data to the
internal buffer w/o logging it in the usual ways.

This method clears the internal log buffer.

This method should be called after it has been fork()ed to clear the internal
log buffer.

Retrieve those entries from the buffer that are gte the given severity.

Log a message. Takes a hash containing at least "message" and "level".

Call on instatiation to set this class up.

Translates a numeric level to severity string.

Translates a severity string to a numeric level.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 13:

    Unknown directive: =attr

- Around line 18:

    Unknown directive: =method

- Around line 24:

    Unknown directive: =method

- Around line 28:

    Unknown directive: =method

- Around line 33:

    Unknown directive: =method

- Around line 37:

    Unknown directive: =method

- Around line 41:

    Unknown directive: =method

- Around line 45:

    Unknown directive: =method

- Around line 49:

    Unknown directive: =method
