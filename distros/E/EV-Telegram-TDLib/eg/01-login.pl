#!/usr/bin/env perl
# 01-login.pl - user login with phone number, SMS code and 2FA password
#
# Demonstrates: phone_number authorization, the on_code and on_password
# credential callbacks, me(), and a clean close.
#
# This is the script that creates the session database; the other examples
# reuse it. The database directory (default ./tdlib-db) holds the session:
# it is exactly as sensitive as a password, so do not commit it, back it up,
# or leave it world-readable.
#
# Environment:
#   TD_API_ID, TD_API_HASH  application credentials from https://my.telegram.org
#   TD_PHONE                phone number in international format, e.g. +10000000000
#   TD_DATABASE_DIRECTORY   optional, default ./tdlib-db
#
# Run: perl eg/01-login.pl   (add -Mblib to run from a built checkout)

use strict;
use warnings;
use EV;
use EV::Telegram::TDLib;

sub env_or_die {
    my ($name, $hint) = @_;
    return $ENV{$name} // die "missing environment variable $name ($hint)\n";
}

# declared before the client so the credential callbacks can break the loop:
# a die inside one is contained and reported, never propagated, so it would
# leave EV::run going and the script hanging
my $status = 0;
my $interrupted = 0;

my $td = EV::Telegram::TDLib->new(
    api_id             => env_or_die('TD_API_ID', 'api_id from https://my.telegram.org'),
    api_hash           => env_or_die('TD_API_HASH', 'api_hash from https://my.telegram.org'),
    phone_number       => env_or_die('TD_PHONE', 'phone number in international format'),
    database_directory => $ENV{TD_DATABASE_DIRECTORY} // 'tdlib-db',
    on_code => sub {
        my ($info, $submit) = @_;
        print "code from Telegram: ";
        my $code = <STDIN>;
        if (!defined $code) {
            warn "interrupted\n";
            $status = 1;
            return EV::break;
        }
        chomp $code;
        $submit->($code);
    },
    on_password => sub {
        my ($info, $submit) = @_;
        my $hint = $info->{password_hint};
        print "2FA password", (defined $hint && length $hint ? " (hint: $hint)" : ''), ": ";
        # Echo off while it is typed, so the password does not reach the
        # terminal or whatever is recording it. Restored through a guard
        # object rather than a plain statement after the read: the realistic
        # way out of here is Ctrl-C, and a terminal left with echo off
        # outlives this program -- bash happens to restore its own snapshot,
        # but sh, make, ssh and CI harnesses do not, and the next password
        # typed there is invisible.
        # The handler dies rather than setting a flag and returning: perl
        # defers signals, and a handler that returns lets it resume the
        # interrupted read, so Ctrl-C would set the flag and then go on
        # waiting for a password line. Dying unwinds the readline; the eval
        # keeps it local, and the guard restores echo as the scope goes.
        my $password = do {
            my $guard = EchoOff->new;
            local $SIG{INT} = local $SIG{TERM} = local $SIG{HUP} = sub {
                $interrupted = 1;
                die "interrupted\n";
            };
            my $p = eval { <STDIN> };
            defined $p ? do { chomp $p; $p } : undef;
        };
        print "\n" if -t STDIN;
        # an interrupted or closed STDIN must not submit the empty string as
        # the password: that spends a login attempt and can lock the account
        if ($interrupted || !defined $password) {
            warn "interrupted\n";
            $status = 1;
            return EV::break;
        }
        $submit->($password);
    },
    on_error => sub { warn "tdlib: $_[0]\n" },
);

sub fail {
    my ($what, $err) = @_;
    warn "$what: $err->{message}\n";
    $status = 1;
    EV::break;
    return 1;
}

$td->login(sub {
    my (undef, $err) = @_;
    return fail('login failed', $err) if $err;
    $td->me(sub {
        my ($user, $err) = @_;
        return fail('getMe failed', $err) if $err;
        # user has no top-level username; the usernames object holds them
        my $names = $user->{usernames} // {};
        my $username = ($names->{active_usernames} // [])->[0]
            // $names->{editable_username};
        printf "logged in as %s %s (id %d%s)\n",
            $user->{first_name}, $user->{last_name} // '', $user->{id},
            defined $username ? ", \@$username" : '';
        $td->close(sub { EV::break });
    });
});

EV::run;
exit $status;

# Turns terminal echo off for as long as the object lives, and restores the
# exact previous settings when it goes away -- on a normal return, on a die,
# and on the signal paths above. POSIX::Termios rather than shelling out to
# stty so the original flags are what comes back, not a guess at them.
package EchoOff;
use POSIX qw(:termios_h);

sub new {
    my ($class) = @_;
    return bless { }, $class unless -t STDIN;
    my $t = POSIX::Termios->new;
    $t->getattr(fileno STDIN) or return bless { }, $class;
    my $self = bless { termios => $t, lflag => $t->getlflag }, $class;
    $t->setlflag($self->{lflag} & ~ECHO);
    $t->setattr(fileno STDIN, TCSANOW);
    return $self;
}

sub DESTROY {
    my ($self) = @_;
    return unless $self->{termios};
    $self->{termios}->setlflag($self->{lflag});
    $self->{termios}->setattr(fileno STDIN, TCSANOW);
    delete $self->{termios};
}
