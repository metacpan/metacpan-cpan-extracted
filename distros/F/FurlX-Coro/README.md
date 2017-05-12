# NAME

FurlX::Coro - Multiple HTTP requests with Coro

# VERSION

This document describes FurlX::Coro version 1.01.

# SYNOPSIS

    use strict;
    use warnings;
    use Coro;
    use FurlX::Coro;

    my @coros;
    foreach my $url(@ARGV) {
        push @coros, async {
            print "fetching $url\n";
            my $ua  = FurlX::Coro->new();
            $ua->env_proxy();
            my $res = $ua->head($url);
            printf "%s: %s\n", $url, $res->status_line();
        }
    }

    $_->join for @coros;

# DESCRIPTION

This is a wrapper to `Furl` for asynchronous HTTP requests with `Coro`.

# INTERFACE

Interface is the same as `Furl`.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[Furl](http://search.cpan.org/perldoc?Furl)

[Coro](http://search.cpan.org/perldoc?Coro)

# AUTHOR

Fuji, Goro (gfx) <gfuji@cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
