package Kwiki::BroadcastMessage;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_id => 'broadcast_message';
const cgi_class => 'Kwiki::BroadcastMessage::CGI';

sub register {
    my $register = shift;
    $register->add(
            status => 'broadcast_message',
            template => 'broadcast_message.html'
            );
    $register->add( action => 'broadcast_message');
    $register->add( action => 'broadcast_message_add');
    $register->add(
            toolbar => 'broadcast_message_button',
            template => 'broadcast_message_button.html'
            );
}

sub html {
    my $ret;
    my $messages = $self->fetch_messages;
    for(@$messages) {
        $ret .= qq{<div class="broadcast_message_single">$_</div>};
    }
    return $ret;
}

sub broadcast_message {
    $self->render_screen(screen_title => "Broadcast...");
}

sub broadcast_message_add {
    if($self->cgi->broadcast_message_delete) {
	$self->store_message('');
    } else {
	$self->store_message($self->cgi->message);
    }
    $self->redirect($self->hub->config->main_page);
}

sub message_db {
    io->catfile($self->plugin_directory,"messages");
}

sub store_message {
    $self->message_db->print($_[0]);
}

sub fetch_messages {
    return [ @{$self->message_db} ];
}

package Kwiki::BroadcastMessage::CGI;
use base 'Kwiki::CGI';

cgi 'user_name';
cgi 'message' => -utf8;
cgi 'broadcast_message_delete';

package Kwiki::BroadcastMessage;

__DATA__

=head1 NAME

  Kwiki::BroadcastMessage - Broadcasting Messages on Kwiki site.

=head1 DESCRIPTION

This plugin provide a broadcasting message interface for people to
temporarily display some words on your status pane. Just install this
plugin, and there would be an extra item "Broadcast" on the toolbar.

The message would be kept until someone explict delete it or modify
it.

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__template/tt2/broadcast_message.html__
<div id="broadcast_message">
[% hub.broadcast_message.html %]
</div>
__template/tt2/broadcast_message_button.html__
<a href="[% script_name %]?action=broadcast_message" title="Broadcast Message">
[% INCLUDE broadcast_message_button_icon.html %]
</a>
__template/tt2/broadcast_message_button_icon.html__
Broadcast
__template/tt2/broadcast_message_content.html__
<div id="broadcast_message_content">
<form action="[% script_name %]" method="GET">
<input type="hidden" name="action" value="broadcast_message_add" />
<input type="hidden" name="user_name" value="[% hub.users.current.name %]" />
<input type="submit" name="broadcast_message_add" value="Broadcast" />
<input type="submit" name="broadcast_message_delete" value="Delete Broadcast" />
<p>Message:</p>
<textarea name="message"></textarea>
</form>
</div>
