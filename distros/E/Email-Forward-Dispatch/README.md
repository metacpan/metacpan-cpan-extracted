[![Build Status](https://travis-ci.org/hirobanex/p5-Email-Forward-Dispatch.svg?branch=master)](https://travis-ci.org/hirobanex/p5-Email-Forward-Dispatch) [![Coverage Status](https://img.shields.io/coveralls/hirobanex/p5-Email-Forward-Dispatch/master.svg)](https://coveralls.io/r/hirobanex/p5-Email-Forward-Dispatch?branch=master)
# NAME

Email::Forward::Dispatch - use ~/.forward plaggerable

# SYNOPSIS

    # in /home/hirobanex/script.pl
    use Email::Forward::Dispatch;

    my $dispatcher = Email::Forward::Dispatch->new(
        is_forward_cb   => sub { ($_[1]->header('To') =~ /hirobanex\@gmail\.com/) ? 1 : 0 },
        forward_cb      => sub { print $_[1]->header('To') },
    );

    or 

    my $dispatcher = Email::Forward::Dispatch->new(
        mail      => scalar do {local $/; <STDIN>; },
        hooks_dir => "MyMailNotify::Hooks",
    );

    $dispatcher->run;


    #in /home/hirobanex/.forward
    "|exec /home/hirobanex/script.pl"

# DESCRIPTION

Email::Forward::Dispatch is Email forward utility tool. 

# LICENSE

Copyright (C) Hiroyuki Akabane.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyuki Akabane <hirobanex@gmail.com>
