#!/usr/bin/env perl
# 08-tickit-chat.pl - a two-pane terminal client driven by the EV loop
#
# The same shape as 07-gtk4-chat.pl, in a terminal: chats on the left, the
# selected conversation on the right. Tickit runs on IO::Async, and
# IO::Async::Loop::EV backs that with EV -- so the widgets and the TDLib
# pump share one loop, exactly as EV::Glib arranges for GTK4.
#
# Keys: Up/Down pick a chat, type to compose, Enter sends, Ctrl-C quits.
#
# Uses the session created by 01-login.pl. A user account only: TDLib
# refuses the chat list and history to a bot.
#
# The database directory (default ./tdlib-db) holds the session: it is
# exactly as sensitive as a password.
#
# Needs Tickit and IO::Async::Loop::EV, loaded at run time so this file
# still compiles where they are absent:
#
#   TD_API_ID=... TD_API_HASH=... TD_PHONE=+... perl eg/08-tickit-chat.pl

use strict;
use warnings;
use EV;
use EV::Telegram::TDLib;
use POSIX ();

sub env_or_die {
    my ($name, $what) = @_;
    $ENV{$name} // die "missing environment variable $name ($what)\n";
}

# Loaded here rather than with use, so perl -c succeeds without them.
sub boot_tickit {
    eval {
        require IO::Async::Loop::EV;
        require Tickit::Async;
        require Tickit::Widget::Static;
        require Tickit::Widget::Entry;
        require Tickit::Widget::VBox;
        require Tickit::Widget::VSplit;
        require Tickit::Widget::Frame;
        1;
    } or die "Tickit and IO::Async::Loop::EV are required: $@";
}

boot_tickit();

# --- widgets ----------------------------------------------------------

my $chats_pane = Tickit::Widget::Static->new(text => 'loading chats...');
my $msgs_pane  = Tickit::Widget::Static->new(text => 'pick a chat with Up/Down');
my $status     = Tickit::Widget::Static->new(text => 'connecting...');

my $entry = Tickit::Widget::Entry->new(
    on_enter => sub {
        my ($self) = @_;
        my $text = $self->text;
        $self->set_text('');
        deliver($text);
    },
);

my $left = Tickit::Widget::Frame->new(
    title => 'Chats', style => { linetype => 'single' },
);
$left->set_child($chats_pane);

my $convo = Tickit::Widget::Frame->new(
    title => 'Messages', style => { linetype => 'single' },
);
$convo->set_child($msgs_pane);

my $right = Tickit::Widget::VBox->new;
$right->add($convo, expand => 1);
$right->add($entry);

my $split = Tickit::Widget::VSplit->new;
$split->set_left_child($left);
$split->set_right_child($right);

my $root = Tickit::Widget::VBox->new;
$root->add($split, expand => 1);
$root->add($status);

# Tickit::Async takes an IO::Async loop; giving it the EV-backed one is what
# puts the terminal and the TDLib pump on the same event loop.
my $loop   = IO::Async::Loop::EV->new;
my $tickit = Tickit::Async->new(root => $root);
$loop->add($tickit);

# --- state ------------------------------------------------------------

my @chats;         # ordered, newest conversation first
my $cursor = 0;    # which of @chats is selected
my $current;       # chat_id shown on the right
my @lines;         # rendered message lines for the current chat

sub one_line {
    my ($s, $max) = @_;
    $s //= '';
    $s =~ s/\s+/ /g;
    return length($s) > $max ? substr($s, 0, $max - 1) . '~' : $s;
}

sub preview_of {
    my ($msg) = @_;
    return '' unless $msg;
    my $c = $msg->{content} || {};
    my $t = ($c->{text} || {})->{text} // ($c->{caption} || {})->{text};
    return $t if defined $t && length $t;
    my $type = $c->{'@type'} // 'message';
    $type =~ s/^message//;
    return $type eq '' ? 'message' : lc $type;
}

sub draw_chats {
    my $rows = $chats_pane->window ? $chats_pane->window->lines : 20;
    # keep the cursor on screen without a scrollable widget
    my $first = $cursor - int($rows / 2);
    $first = 0 if $first < 0;
    $first = @chats - $rows if $first > @chats - $rows;
    $first = 0 if $first < 0;

    my @out;
    for my $i ($first .. $#chats) {
        last if @out >= $rows;
        my $c = $chats[$i];
        push @out, sprintf '%s %s',
            ($i == $cursor ? '>' : ' '),
            one_line($c->{title} // '(no title)', 24);
    }
    $chats_pane->set_text(join "\n", @out);
}

sub draw_messages {
    my $rows = $msgs_pane->window ? $msgs_pane->window->lines : 20;
    my @tail = @lines > $rows ? @lines[-$rows .. -1] : @lines;
    $msgs_pane->set_text(join "\n", @tail);
}

sub add_message {
    my ($msg) = @_;
    my $when = $msg->{date} ? POSIX::strftime('%H:%M', localtime $msg->{date}) : '--:--';
    push @lines, sprintf '%s %s %s',
        $when, ($msg->{is_outgoing} ? '>' : '<'), one_line(preview_of($msg), 200);
    draw_messages();
}

# --- the client -------------------------------------------------------

my $td = EV::Telegram::TDLib->new(
    api_id             => env_or_die('TD_API_ID', 'from https://my.telegram.org'),
    api_hash           => env_or_die('TD_API_HASH', 'from https://my.telegram.org'),
    database_directory => $ENV{TD_DATABASE_DIRECTORY} // 'tdlib-db',
    on_error           => sub { $status->set_text('! ' . one_line($_[0], 70)) },
    phone_number       => env_or_die('TD_PHONE', 'phone number in international format'),
    on_code            => sub {
        my ($info, $submit) = @_;
        # the terminal belongs to Tickit, so ask before it starts
        print STDERR 'login code: ';
        chomp(my $c = <STDIN> // '');
        $submit->($c);
    },
    on_password        => sub {
        my ($info, $submit) = @_;
        print STDERR '2FA password: ';
        # Echo off while it is typed, restored through a guard object
        # so an interrupt cannot leave the terminal silent afterwards.
        # The handler dies rather than returning: perl defers signals,
        # and a handler that returns lets it resume the read.
        my $p = do {
            my $guard = EchoOff->new;
            local $SIG{INT} = local $SIG{TERM} = local $SIG{HUP}
                = sub { die "interrupted\n" };
            my $line = eval { <STDIN> };
            defined $line ? do { chomp $line; $line } : undef;
        };
        print STDERR "\n";
        return warn "no password given\n" unless defined $p;
        $submit->($p);
    },
);

sub open_chat {
    my ($index) = @_;
    my $chat = $chats[$index] or return;
    $current = $chat->{id};
    $convo->set_title(one_line($chat->{title} // 'chat', 40));
    @lines = ('loading...');
    draw_messages();

    $td->history($current, limit => 100, sub {
        my ($msgs, $err) = @_;
        return $status->set_text('history: ' . one_line($err->{message}, 60)) if $err;
        @lines = ();
        add_message($_) for reverse @$msgs;
        @lines = ('(no messages here yet)') unless @lines;
        draw_messages();
        $status->set_text(sprintf '%d messages  |  Up/Down chat, Enter send, Ctrl-C quit',
            scalar @$msgs);
        $td->mark_read($current, sub { });
    });
}

sub deliver {
    my ($text) = @_;
    return unless defined $text && length $text && defined $current;
    # the bubble is not drawn here: updateNewMessage reports the message
    # first, with a temporary id, and this callback fires later with the
    # final one -- drawing in both places would show it twice
    $td->send_message($current, $text, sub {
        my ($msg, $err) = @_;
        $status->set_text('send: ' . one_line($err->{message}, 60)) if $err;
    });
}

$td->on_message(sub {
    my ($msg) = @_;
    return unless defined $current && $msg->{chat_id} == $current;
    add_message($msg);
    $td->mark_read($current, sub { }) unless $msg->{is_outgoing};
});

# --- keys -------------------------------------------------------------

$tickit->bind_key('Up' => sub {
    return unless @chats;
    $cursor-- if $cursor > 0;
    draw_chats();
    open_chat($cursor);
});
$tickit->bind_key('Down' => sub {
    return unless @chats;
    $cursor++ if $cursor < $#chats;
    draw_chats();
    open_chat($cursor);
});
# --- go ---------------------------------------------------------------

my %seen;
$td->on_chat(sub { $seen{ $_[0]{id} } = 1 });

$td->login(sub {
    my (undef, $err) = @_;
    return $status->set_text('login: ' . one_line($err->{message}, 60)) if $err;
    $status->set_text('loading chats...');

    my $load;
    $load = sub {
        $td->load_chats(200, sub {
            my ($res, $err) = @_;
            return $status->set_text('chats: ' . one_line($err->{message}, 60)) if $err;
            return $load->() if $res;      # a page arrived; ask for the next

            @chats = sort {
                (($b->{last_message} || {})->{date} // 0)
                    <=> (($a->{last_message} || {})->{date} // 0)
                    || ($a->{title} // '') cmp ($b->{title} // '')
            } grep { defined } map { $td->chat($_) } keys %seen;

            return $chats_pane->set_text('(no chats)') unless @chats;
            draw_chats();
            open_chat(0);                  # newest, so the right pane is never blank
        });
    };
    $load->();
});

$tickit->run;

# Tickit leaves run on Ctrl-C by itself, before a key binding could see it,
# so the client is closed here: leaving it to exit would tear TDLib down
# mid-flight
my $closed;
$td->close(sub { $closed = 1; EV::break });
EV::run unless $closed;

# Turns terminal echo off for as long as the object lives, and restores the
# exact previous settings when it goes away. POSIX::Termios rather than
# shelling out to stty so the original flags are what comes back, not a guess
# at them; a terminal left with echo off outlives this program.
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
