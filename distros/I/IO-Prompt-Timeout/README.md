# NAME

IO::Prompt::Timeout - Simple prompt interface with timeout.

# SYNOPSIS

    use IO::Prompt::Timeout qw(:all);
    my $answer = prompt('Yes or No? (y/n)', %option);
    my $is_timeout = has_prompt_timed_out();

    # Specifying timeout seconds
    my $answer = prompt('Yes or No? (y/n) Answer in 10 seconds.', timeout => 10);

    # Specifying default answer
    my $answer = prompt('Yes or No? (y/n)', default => 'n');

# DESCRIPTION

__IO::Prompt::Timeout__ provides _prompt_ subroutine most of which comes from
[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker).

It also has timeout feature just like [Prompt::Timeout](https://metacpan.org/pod/Prompt::Timeout).
The default timeout seconds is 60. When prompt timed out, the default answer
can be taken when it's set by option.

Unlike Prompt::Timeout, this module uses [IO::Select](https://metacpan.org/pod/IO::Select) for timeout procedure.
The function of clearing timer by a single key click is not supported which is
implemented in Prompt::Timeout.

# SUBROUTINES

## prompt : Answer(SCALAR)

Show prompt and returns the answer by user's input.

## has\_prompt\_timed\_out : BOOL

Called after a _prompt_ call.
Returns if _prompt_ subroutine has timed out or not.

# ENVIRONMENT VARIABLES

- __$ENV{PERL\_IOPT\_USE\_DEFAULT}__

    If set true, _prompt_ will always return the default answer without waiting for
    user input.

# SEE ALSO

[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker),
[IO::Prompt::Tiny](https://metacpan.org/pod/IO::Prompt::Tiny),
[Prompt::Timeout](https://metacpan.org/pod/Prompt::Timeout),
[IO::Select](https://metacpan.org/pod/IO::Select)

# LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

YASUTAKE Kiyoshi <yasutake.kiyoshi@gmail.com>
