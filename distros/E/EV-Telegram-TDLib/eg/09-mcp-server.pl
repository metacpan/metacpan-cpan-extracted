#!/usr/bin/env perl
# 09-mcp-server.pl - expose Telegram to an MCP client, over the EV loop
#
# Speaks newline-delimited JSON-RPC on stdio, the transport MCP clients use
# for local servers. The point of interest is that nothing blocks: stdin is
# an EV::io watcher, so it shares the loop with the TDLib pump, and a
# tools/call is answered when TDLib replies rather than by waiting for it.
#
# Tools: list_chats, history, send_message.
#
# Uses the session created by 01-login.pl, and a user account only: TDLib
# refuses the chat list and history to a bot. Add to an MCP client's
# config, for example:
#
#   { "mcpServers": { "telegram": {
#       "command": "perl",
#       "args": ["/path/to/eg/09-mcp-server.pl"],
#       "env": { "TD_API_ID": "...", "TD_API_HASH": "...",
#                "TD_PHONE": "+...", "TD_DATABASE_DIRECTORY": "/path/to/db" }
#   } } }
#
# The session must already exist: a server started on stdio has nowhere to
# ask for a login code. Run 01-login.pl once first.
#
# The database directory holds that session: it is exactly as sensitive as
# a password, and so is anything this server can reach.

use strict;
use warnings;
use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;

my $J = Cpanel::JSON::XS->new->utf8->canonical;
$| = 1;

sub env_or_die {
    my ($name, $what) = @_;
    $ENV{$name} // die "missing environment variable $name ($what)\n";
}

my @TOOLS = (
    {
        name        => 'list_chats',
        description => 'List Telegram chats, newest conversation first',
        inputSchema => {
            type       => 'object',
            properties => {
                limit => { type => 'integer', description => 'how many to return', default => 30 },
            },
        },
    },
    {
        name        => 'history',
        description => 'Recent messages of one chat, newest last',
        inputSchema => {
            type       => 'object',
            properties => {
                chat_id => { type => 'integer', description => 'chat id from list_chats' },
                limit   => { type => 'integer', description => 'how many messages', default => 20 },
            },
            required   => ['chat_id'],
        },
    },
    {
        name        => 'send_message',
        description => 'Send a text message to a chat',
        inputSchema => {
            type       => 'object',
            properties => {
                chat_id => { type => 'integer', description => 'chat id from list_chats' },
                text    => { type => 'string',  description => 'what to send' },
            },
            required   => ['chat_id', 'text'],
        },
    },
);

sub reply {
    my ($id, $result) = @_;
    return unless defined $id;          # a notification wants no answer
    print $J->encode({ jsonrpc => '2.0', id => $id, result => $result }), "\n";
}

sub rpc_error {
    my ($id, $code, $message) = @_;
    print $J->encode({ jsonrpc => '2.0', id => $id,
                       error => { code => $code, message => $message } }), "\n";
}

sub reply_text {
    my ($id, $text, $is_error) = @_;
    reply($id, {
        content => [ { type => 'text', text => $text } ],
        isError => $is_error ? Cpanel::JSON::XS::true() : Cpanel::JSON::XS::false(),
    });
}

sub describe {
    my ($msg) = @_;
    my $c = $msg->{content} || {};
    # not $c->{text}{text}: that autovivifies an empty text hash into the
    # cached message on every photo, sticker and call
    my $t = ($c->{text} || {})->{text} // ($c->{caption} || {})->{text};
    unless (defined $t && length $t) {
        $t = $c->{'@type'} // 'message';
        $t =~ s/^message//;
        $t = '<' . (length $t ? lc $t : 'message') . '>';
    }
    return sprintf '%s %s', ($msg->{is_outgoing} ? '>' : '<'), $t;
}

# --- the client -------------------------------------------------------

my $ready = 0;
my $login_error;
my %seen;

my $td = EV::Telegram::TDLib->new(
    api_id             => env_or_die('TD_API_ID', 'from https://my.telegram.org'),
    api_hash           => env_or_die('TD_API_HASH', 'from https://my.telegram.org'),
    database_directory => $ENV{TD_DATABASE_DIRECTORY} // 'tdlib-db',
    # never write to stdout: it carries the protocol
    on_error           => sub { warn "tdlib: $_[0]\n" },
    on_chat            => sub { $seen{ $_[0]{id} } = 1 },
    phone_number       => env_or_die('TD_PHONE', 'phone number in international format'),
    # stdio belongs to the protocol, so there is no way to prompt: the
    # session has to exist already
    on_code            => sub { warn "no session: run 01-login.pl first\n" },
    on_password        => sub { warn "no session: run 01-login.pl first\n" },
);

$td->login(sub {
    my (undef, $err) = @_;
    if ($err) {
        $login_error = $err->{message};
        return warn "login failed: $login_error\n";
    }
    $ready = 1;
    warn "telegram mcp server ready\n";
});

# --- tools ------------------------------------------------------------

sub tool_list_chats {
    my ($id, $args) = @_;
    my $limit = $args->{limit} || 30;
    # a closure that names itself holds a reference to itself and is never
    # collected, so this one is cleared on every path out of the paging loop
    my $load;
    $load = sub {
        $td->load_chats(200, sub {
            my ($res, $err) = @_;
            if ($err) { undef $load; return reply_text($id, "load_chats: $err->{message}", 1) }
            return $load->() if $res;          # another page arrived
            undef $load;                       # break the cycle before replying
            my @chats = sort {
                (($b->{last_message} || {})->{date} // 0)
                    <=> (($a->{last_message} || {})->{date} // 0)
            } grep { defined } map { $td->chat($_) } keys %seen;
            @chats = @chats[0 .. $limit - 1] if @chats > $limit;
            reply_text($id, join "\n",
                map { sprintf '%d  %s', $_->{id}, $_->{title} // '(no title)' } @chats);
        });
    };
    $load->();
}

sub tool_history {
    my ($id, $args) = @_;
    my $chat = $args->{chat_id};
    return reply_text($id, 'chat_id is required', 1) unless defined $chat;
    $td->history($chat, limit => $args->{limit} || 20, sub {
        my ($msgs, $err) = @_;
        return reply_text($id, "history: $err->{message}", 1) if $err;
        return reply_text($id, '(no messages)') unless @$msgs;
        reply_text($id, join "\n", map { describe($_) } reverse @$msgs);
    });
}

sub tool_send_message {
    my ($id, $args) = @_;
    my ($chat, $text) = @{$args}{qw(chat_id text)};
    return reply_text($id, 'chat_id and text are required', 1)
        unless defined $chat && defined $text && length $text;
    $td->send_message($chat, $text, sub {
        my ($msg, $err) = @_;
        return reply_text($id, "send: $err->{message}", 1) if $err;
        reply_text($id, "sent, message id $msg->{id}");
    });
}

my %DISPATCH = (
    list_chats   => \&tool_list_chats,
    history      => \&tool_history,
    send_message => \&tool_send_message,
);

# --- protocol ---------------------------------------------------------

sub handle {
    my ($req) = @_;
    my ($method, $id) = @{$req}{qw(method id)};
    return unless defined $method;

    if ($method eq 'initialize') {
        return reply($id, {
            protocolVersion => '2024-11-05',
            capabilities    => { tools => {} },
            serverInfo      => { name => 'telegram', version => $EV::Telegram::TDLib::VERSION },
        });
    }
    return reply($id, { tools => \@TOOLS }) if $method eq 'tools/list';
    return reply($id, {})                   if $method eq 'ping';

    if ($method eq 'tools/call') {
        my $name = $req->{params}{name} // '';
        my $tool = $DISPATCH{$name}
            or return reply_text($id, "unknown tool: $name", 1);
        return reply_text($id,
            $login_error ? "login failed: $login_error" : 'not connected to Telegram yet',
            1) unless $ready;
        # the tool answers when TDLib does; nothing waits here
        return $tool->($id, $req->{params}{arguments} // {});
    }

    return unless defined $id;
    rpc_error($id, -32601, "method not found: $method");
}

# stdin as an EV watcher, so reading the protocol never stalls the pump
my $buf = '';
my $stdin = EV::io *STDIN, EV::READ, sub {
    my ($w) = @_;
    my $n = sysread STDIN, my $chunk, 65536;
    if (!defined $n) { return if $!{EAGAIN} || $!{EINTR}; $n = 0 }
    if ($n == 0) {                      # the client closed the pipe
        # stop first: an fd at EOF stays readable, so otherwise every loop
        # iteration lands back here and calls close() again, at full CPU
        $w->stop;
        $td->close(sub { EV::break });
        return;
    }
    $buf .= $chunk;
    while ($buf =~ s/^([^\n]*)\n//) {
        my $line = $1;
        next unless length $line;
        # malformed input is answered, not dropped: a client waiting for a
        # reply to that line would otherwise wait for ever
        my $req = eval { $J->decode($line) };
        if (!defined $req)      { rpc_error(undef, -32700, 'parse error');     next }
        if (ref $req ne 'HASH') { rpc_error(undef, -32600, 'invalid request'); next }
        # a tool that dies -- the module refusing an argument, say -- must
        # still answer, and must not strand the lines left in the buffer
        next if eval { handle($req); 1 };
        (my $err = $@) =~ s/ at \S+ line \d+.*//s;
        rpc_error($req->{id}, -32603, $err) if defined $req->{id};
    }
};

EV::run;
