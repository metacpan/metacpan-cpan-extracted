package Hubot::Scripts::Bundle;
$Hubot::Scripts::Bundle::VERSION = '0.1.10';
1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Scripts::Bundle - optional scripts for hubot

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

example F<hubot-scripts.json>

    [
        "redisBrain",
        "help",
        "ping",
        "uptime",
        "eval",
	    "tell"
    ]

and then,

    $ hubot

=head1 DESCRIPTION

hubot has extensible its feature by scripts.
so scripts would be increase. I don't know how many there are.

maintaining various distribution is not easy.
so C<foo>, C<bar>, C<baz>, C<..> scripts will be added to this.

=head1 SCRIPTS

=over

=item redisBrain

using redis as an external storage for robot's brain

=item ping

    me> hubot: ping
    hubot> me: PONG
    me> hubot: die
    hubot> Goodbye, cruel world.
    * hubot has quit

=item uptime

    me> hubot: uptime
    hubot> I've been sentient for 0 years, 00 months, 2 days, 00 hours, 252 minutes, 07 seconds

=item eval

    me> eval print $^V;
    hubot> v5.14.2

evaluate <code> and show the result via L<http://api.dan.co.jp/lleval.cgi>

=item tell

Tell Hubot to send a user a message when present in the room

    me> hubot tell <user> <message>

=item bugzilla

    me> bug <id>|<keyword>
    me> bug search <keyword>

=item storable

using file as an external storage via L<Storable> for robot's brain

=back

=head1 SEE ALSO

L<https://github.com/aanoaa/p5-hubot-scripts>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
