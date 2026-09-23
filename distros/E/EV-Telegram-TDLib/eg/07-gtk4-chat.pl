#!/usr/bin/env perl
# 07-gtk4-chat.pl - a two-pane GTK4 client driven by the EV loop
#
# Chats on the left, the selected conversation on the right. Demonstrates
# running a GTK4 interface and a Telegram client in one process without two
# competing main loops: EV::Glib embeds the glib context into EV, so EV::run
# drives both the widgets and the TDLib pump, and there is no gtk_main and no
# $app->run anywhere in this file.
#
# Uses the session created by 01-login.pl. A user account only: TDLib
# refuses the chat list and history to a bot.
#
# The database directory (default ./tdlib-db) holds the session: it is
# exactly as sensitive as a password.
#
# Needs GTK4 and Glib::Object::Introspection, loaded at run time so this file
# still compiles where they are absent:
#
#   TD_API_ID=... TD_API_HASH=... TD_PHONE=+... perl eg/07-gtk4-chat.pl

use strict;
use warnings;
use EV;
use EV::Telegram::TDLib;
use POSIX ();

sub env_or_die {
    my ($name, $what) = @_;
    $ENV{$name} // die "missing environment variable $name ($what)\n";
}

# GTK4 is pulled in here rather than with use, so that perl -c succeeds on
# machines without it -- the dist's own example-compile test runs everywhere.
sub boot_gtk {
    eval {
        require EV::Glib;   # on load, glib's default context joins the EV loop
        # loading the bindings this late means their INIT blocks cannot run,
        # which perl mentions and which does not matter here
        local $SIG{__WARN__} = sub {
            warn @_ unless $_[0] =~ /Too late to run INIT block/;
        };
        require Glib::Object::Introspection;
        Glib::Object::Introspection->setup(
            basename => 'Gtk', version => '4.0', package => 'Gtk4');
        Glib::Object::Introspection->setup(
            basename => 'Gdk', version => '4.0', package => 'Gdk');
        Gtk4::init();
        1;
    } or die "GTK4 and Glib::Object::Introspection are required: $@";
}

boot_gtk();

# --- looks ------------------------------------------------------------

my $CSS = <<'CSS';
.sidebar          { background: alpha(currentColor, 0.03); }
.chat-title       { font-weight: bold; }
.chat-preview     { opacity: 0.55; font-size: 90%; }
.chat-empty       { opacity: 0.5; font-style: italic; }
.bubble           { padding: 6px 10px; border-radius: 12px; }
.bubble-in        { background: alpha(currentColor, 0.08); }
.bubble-out       { background: alpha(@accent_bg_color, 0.30); }
.stamp            { opacity: 0.45; font-size: 80%; }
.status           { opacity: 0.6; font-size: 90%; }
.placeholder      { opacity: 0.45; }
CSS

{
    my $provider = Gtk4::CssProvider->new;
    eval { $provider->load_from_string($CSS); 1 }
        or $provider->load_from_data($CSS, length $CSS);
    Gtk4::StyleContext::add_provider_for_display(
        Gdk::Display::get_default(), $provider, 600);
}

# --- widgets ----------------------------------------------------------

my $window = Gtk4::Window->new;
$window->set_default_size(900, 600);

my $header = Gtk4::HeaderBar->new;
my $title  = Gtk4::Label->new('EV::Telegram::TDLib');
$title->add_css_class('chat-title');
$header->set_title_widget($title);

my $status = Gtk4::Label->new('connecting...');
$status->add_css_class('status');
$header->pack_end($status);
$window->set_titlebar($header);

# left: the chat list
my $chat_list = Gtk4::ListBox->new;
$chat_list->set_selection_mode('single');
$chat_list->add_css_class('navigation-sidebar');

my $chat_scroll = Gtk4::ScrolledWindow->new;
$chat_scroll->set_child($chat_list);
$chat_scroll->set_policy('never', 'automatic');

my $sidebar = Gtk4::Box->new('vertical', 0);
$sidebar->add_css_class('sidebar');
$sidebar->append($chat_scroll);
$chat_scroll->set_vexpand(1);

# right: the conversation
my $msg_list = Gtk4::ListBox->new;
$msg_list->set_selection_mode('none');
$msg_list->set_margin_top(8);
$msg_list->set_margin_bottom(8);
$msg_list->set_margin_start(10);
$msg_list->set_margin_end(10);

my $msg_scroll = Gtk4::ScrolledWindow->new;
$msg_scroll->set_child($msg_list);
$msg_scroll->set_vexpand(1);
$msg_scroll->set_policy('never', 'automatic');

my $entry = Gtk4::Entry->new;
$entry->set_placeholder_text('write a message');
$entry->set_hexpand(1);
$entry->set_sensitive(0);

my $send = Gtk4::Button->new_with_label('Send');
$send->add_css_class('suggested-action');
$send->set_sensitive(0);

my $compose = Gtk4::Box->new('horizontal', 6);
$compose->set_margin_top(6);
$compose->set_margin_bottom(8);
$compose->set_margin_start(10);
$compose->set_margin_end(10);
$compose->append($entry);
$compose->append($send);

my $right = Gtk4::Box->new('vertical', 0);
$right->append($msg_scroll);
$right->append(Gtk4::Separator->new('horizontal'));
$right->append($compose);

my $paned = Gtk4::Paned->new('horizontal');
$paned->set_start_child($sidebar);
$paned->set_end_child($right);
$paned->set_position(280);
$paned->set_resize_start_child(0);
$window->set_child($paned);

# --- helpers ----------------------------------------------------------

sub clear_list {
    my ($list) = @_;
    while (my $row = $list->get_first_child) { $list->remove($row) }
}

sub placeholder {
    my ($list, $text) = @_;
    clear_list($list);
    my $l = Gtk4::Label->new($text);
    $l->add_css_class('placeholder');
    $l->set_margin_top(24);
    $list->append($l);
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

sub one_line {
    my ($s, $max) = @_;
    $s //= '';
    $s =~ s/\s+/ /g;
    return length($s) > $max ? substr($s, 0, $max - 1) . "\x{2026}" : $s;
}

sub stamp_of {
    my ($msg) = @_;
    my $d = $msg->{date} or return '';
    return POSIX::strftime('%H:%M', localtime $d);
}

# --- the client -------------------------------------------------------

my %chat_rows;     # chat_id => the sidebar row
my $current;       # chat_id shown on the right

my $td = EV::Telegram::TDLib->new(
    api_id             => env_or_die('TD_API_ID', 'from https://my.telegram.org'),
    api_hash           => env_or_die('TD_API_HASH', 'from https://my.telegram.org'),
    database_directory => $ENV{TD_DATABASE_DIRECTORY} // 'tdlib-db',
    on_error           => sub { $status->set_text(one_line($_[0], 60)) },
    phone_number       => env_or_die('TD_PHONE', 'phone number in international format'),
    on_code            => sub {
        my ($info, $submit) = @_;
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

sub add_message {
    my ($msg) = @_;
    my $text = preview_of($msg);
    my $out  = $msg->{is_outgoing} ? 1 : 0;

    my $label = Gtk4::Label->new($text);
    $label->set_wrap(1);
    $label->set_xalign(0);
    $label->set_max_width_chars(60);
    $label->add_css_class('bubble');
    $label->add_css_class($out ? 'bubble-out' : 'bubble-in');

    my $when = Gtk4::Label->new(stamp_of($msg));
    $when->add_css_class('stamp');

    my $line = Gtk4::Box->new('horizontal', 6);
    $line->set_halign($out ? 'end' : 'start');
    $line->append($when) if $out;
    $line->append($label);
    $line->append($when) unless $out;

    my $row = Gtk4::ListBoxRow->new;
    $row->set_activatable(0);
    $row->set_child($line);
    $msg_list->append($row);
}

sub scroll_to_bottom {
    my $adj = $msg_scroll->get_vadjustment or return;
    # after the rows have been allocated, not before
    my $t; $t = EV::timer 0.05, 0, sub {
        undef $t;
        $adj->set_value($adj->get_upper - $adj->get_page_size);
    };
}

sub open_chat {
    my ($chat_id) = @_;
    $current = $chat_id;
    my $chat = $td->chat($chat_id);
    $title->set_text($chat ? ($chat->{title} // 'chat') : 'chat');
    $entry->set_sensitive(1);
    $send->set_sensitive(1);
    placeholder($msg_list, 'loading...');

    $td->history($chat_id, limit => 40, sub {
        my ($msgs, $err) = @_;
        return $status->set_text('history: ' . one_line($err->{message}, 50)) if $err;
        clear_list($msg_list);
        return placeholder($msg_list, 'no messages here yet') unless @$msgs;
        add_message($_) for reverse @$msgs;
        scroll_to_bottom();
        $status->set_text(scalar(@$msgs) . ' messages');
        $td->mark_read($chat_id, sub { });
    });
}

sub add_chat_row {
    my ($chat) = @_;
    return if $chat_rows{ $chat->{id} };

    my $name = Gtk4::Label->new(one_line($chat->{title} // '(no title)', 30));
    $name->set_xalign(0);
    $name->add_css_class('chat-title');

    my $sub = Gtk4::Label->new(one_line(preview_of($chat->{last_message}), 34));
    $sub->set_xalign(0);
    $sub->add_css_class('chat-preview');

    my $box = Gtk4::Box->new('vertical', 2);
    $box->set_margin_top(8);
    $box->set_margin_bottom(8);
    $box->set_margin_start(10);
    $box->set_margin_end(10);
    $box->append($name);
    $box->append($sub);

    my $row = Gtk4::ListBoxRow->new;
    $row->set_child($box);
    $chat_rows{ $chat->{id} } = $row;
    # the row remembers which chat it is, so selection needs no lookup table
    $row->{td_chat_id} = $chat->{id};
    $chat_list->append($row);
}

$chat_list->signal_connect('row-selected' => sub {
    my (undef, $row) = @_;
    return unless $row && $row->{td_chat_id};
    open_chat($row->{td_chat_id});
});

sub deliver {
    my $text = $entry->get_text;
    return unless length $text && $current;
    $entry->set_text('');
    # the bubble is not drawn here: TDLib reports the message through
    # updateNewMessage first, with a temporary id, and this callback only
    # fires later with the final one. Drawing in both places shows the
    # message twice, so on_message owns the display and this owns errors.
    # It also means messages sent from another device appear by themselves.
    $td->send_message($current, $text, sub {
        my ($msg, $err) = @_;
        $status->set_text('send: ' . one_line($err->{message}, 50)) if $err;
    });
}
$entry->signal_connect(activate => \&deliver);
$send->signal_connect(clicked  => \&deliver);

$td->on_message(sub {
    my ($msg) = @_;
    if (defined $current && $msg->{chat_id} == $current) {
        add_message($msg);
        scroll_to_bottom();
        $td->mark_read($current, sub { }) unless $msg->{is_outgoing};
    }
    # refresh the sidebar preview for whichever chat it belongs to
    my $row = $chat_rows{ $msg->{chat_id} } or return;
    my $box = $row->get_child                or return;
    my $sub = $box->get_last_child           or return;
    $sub->set_text(one_line(preview_of($msg), 34));
});

$window->signal_connect(close_request => sub {
    # close the client before leaving, so TDLib is not torn down mid-flight
    $status->set_text('closing...');
    $td->close(sub { EV::break });
    return 1;
});

placeholder($chat_list, 'loading chats...');
placeholder($msg_list, 'pick a chat on the left');
$window->present;

my %seen;
$td->on_chat(sub { $seen{ $_[0]{id} } = 1 });

$td->login(sub {
    my (undef, $err) = @_;
    return $status->set_text('login: ' . one_line($err->{message}, 50)) if $err;
    $status->set_text('loading chats...');

    my $load;
    $load = sub {
        $td->load_chats(200, sub {
            my ($res, $err) = @_;
            return $status->set_text('chats: ' . one_line($err->{message}, 50)) if $err;
            return $load->() if $res;      # a page arrived; ask for the next

            clear_list($chat_list);
            my @chats = grep { defined }
                        map  { $td->chat($_) } keys %seen;
            # newest conversation first, which is what every client does
            @chats = sort {
                (($b->{last_message} || {})->{date} // 0)
                    <=> (($a->{last_message} || {})->{date} // 0)
                    || ($a->{title} // '') cmp ($b->{title} // '')
            } @chats;
            add_chat_row($_) for @chats;
            $status->set_text(scalar(@chats) . ' chats');
            return placeholder($chat_list, 'no chats') unless @chats;
            # show the newest conversation, so the right pane is never blank
            $chat_list->select_row($chat_rows{ $chats[0]{id} });
        });
    };
    $load->();
});

EV::run;

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
