#! perl

use strict;
use warnings;

use Test::More 0.89;

use ExtUtils::Builder::Action::Command;
use lib 't/lib';
use Test::LivesOK 'lives_ok';

my $action;
lives_ok { $action = ExtUtils::Builder::Action::Command->new(command => [ $^X, '-e0' ]) } 'Can create new object';

is_deeply($action->to_command, [$^X, '-e0'], 'Returns perl -e0');

like($action->to_code, qr/ system \( '.*?','-e0' \) \ and \ die /x, 'to_code returns something that might be sensible');

lives_ok { $action->execute(quiet => 1) } 'Can execute quiet command';

my @messages;
lives_ok { $action->execute(logger => sub { push @messages, @_ }) } 'Can execute logging command';

is(scalar(@messages), 1, 'Got one message');
like($messages[0], qr/\Q$^X\E .+ -e0 \z/x, "Got '$^X -e0' as message");

is($action->preference, 'command', 'Preferred action is "execute"');

done_testing;

