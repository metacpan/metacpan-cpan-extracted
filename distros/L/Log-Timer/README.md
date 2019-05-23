# NAME

Log::Timer - track nested timing information

# SYNOPSIS

    use Log::Timer;

    sub some_action {
        my $sub_timer = subroutine_timer();
        # do things
        ...
    }

# AUTHORS

- Johan Lindstrom <Johan.Lindstrom@broadbean.com>
- Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
