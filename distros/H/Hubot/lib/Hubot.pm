package Hubot;
$Hubot::VERSION = '0.2.8';
1;

=pod

=encoding utf-8

=head1 NAME

Hubot - L<AnyEvent> based L<https://github.com/github/hubot>

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    $ echo '["help"]' > hubot-scripts.json
    $ hubot
    hubot> hubot help
    hubot> exit

=head1 DESCRIPTION

=head2 CONFIGURATION

describe scripts name to F<hubot-scripts.json>

example)

    [
      "help",
      "shorten",
      "ascii"
    ]

each scripts has each congiruation rules.

check it out C<perldoc Hubot::Scripts::E<lt>scriptE<gt>>.

described order can affect the bot's action.
if "shorten" is appear than "tweet", C<http://twitter.com/E<lt>usernameE<gt>/status/E<lt>tweetidE<gt>> processed twice by "shorten" and "tweet".
the secret is behind of `tweet` script.
actually, L<Hubot::Message> C<finish> method.

if F<hubot-scripts.json> is not exist, built-in scripts

"help", "ascii", "roles"

are loaded automatically.

=head1 ADAPTERS

choose the adapter at runtime.

adapters are sharing all `Hubot::Scripts::*` extends scripts.

    $ hubot -a <adapter>

=head2 BUNDLE ADAPTERS

=over

=item L<Hubot::Adapter::Shell>

gives local shell prompt.
good choice for development.

=item L<Hubot::Adapter::Irc>

=item L<Hubot::Adapter::Campfire>

=back

=head2 BUNDLE SCRIPTS

=over

=item L<Hubot::Scripts::help>

    hubot: help

=item L<Hubot::Scripts::ascii>

    ascii hello

=item L<Hubot::Scripts::shorten>

    http://example.com

=item L<Hubot::Scripts::tweet>

    http://twitter.com/KBO_Scores/status/256376098764505088

=item L<Hubot::Scripts::roles>

    hubot: <user> is a <role>
    hubot: who is <user>
    hubot: <user> is not a <role>

=back

=head1 SEE ALSO

=over

=item L<https://github.com/github/hubot>

=item L<https://github.com/github/hubot-scripts>

=item L<Hubot::Robot>

=item L<Hubot::Adapter>

=item L<Hubot::Brain>

=item L<Hubot::Listener>

=item L<Hubot::Message>

=item L<Hubot::Response>

=item L<Hubot::User>

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
