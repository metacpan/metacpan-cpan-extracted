package Kwiki::UserMessage;
use Kwiki::Plugin qw(-Base -XXX);
use mixin 'Kwiki::Installer';
our $VERSION = '0.02';

const class_id    => 'user_message';
const class_title => 'Kwiki User Message';
const cgi_class   => 'Kwiki::UserMessage::CGI';

const css_file => 'user_message.css';
const javascript_file => 'user_message.js';

field cdbi => -init => '$self->hub->cdbi';

field 'display_msg';

sub register {
    my $registry = shift;
    $registry->add(action  => 'user_message');
    $registry->add(toolbar => 'user_message',
		   template => 'user_message_toolbar.html');
}

sub dbinit {
    my $dbpath = io->catfile($self->plugin_directory,"data.sqlt");
    my $db = $self->hub->cdbi;
    $db->base('Kwiki::UserMessage::CDBI');
    $db->connection("dbi:SQLite:".$dbpath->name);
    $db->dbinit unless $dbpath->exists;
}

sub user_message {
    $self->dbinit;
    my $mode = $self->cgi->run_mode || 'list';
    $self->$mode if $self->can($mode);
    $self->render_screen;
}

sub list {}
sub compose {}

sub delete {
    my $id = shift || $self->cgi->id;
    $self->delete_message($id) if $id;

    my $obj = $self->cdbi->retrieve($id);
    $obj->delete if $obj;
}

sub post {
    my $caller_sub = (caller(1))[3];
    if($caller_sub eq 'Kwiki::UserMessage::user_message') {
	if($self->post($self->users->current->name,
		       $self->cgi->to,
		       $self->cgi->subject,
		       $self->cgi->body)) {
	    $self->display_msg("Message Delivered");
	} else {
	    $self->display_msg("Delivery Error");
	}
    } else {
	my ($sender,$receiver,$subject,$body) = @_;
	my $vars = {
		    id => $self->cdbi->maximum_value_of("id")||0 + 1,
		    sender => $sender,
		    receiver => $receiver,
		    subject => $subject,
		    body => $body,
		    ts => scalar(localtime)
		   };
	$self->cdbi->create($vars);
    }
}

sub message_list {
    my $user = shift || $self->users->current->name;
    my $it = $self->cdbi->search( receiver => $user );
    my @obj = $self->retrieve_obj_list($it);
    return \@obj;
}

sub load_message {
    my $id = shift;
    $self->retrieve_obj($self->cdbi->retrieve($id), $self->cdbi->columns());
}

sub retrieve_obj_list {
    my $it = shift || return;
    my $entity = shift || $self->cdbi;
    my @objs;
    my @columns = $entity->columns();
    while(my $obj = $it->next) {
	push @objs, $self->retrieve_obj($obj,@columns);
    }
    return @objs;
}

sub retrieve_obj {
    my ($obj,@columns) = @_;
    return unless ref($obj);
    my $var;
    for(@columns) {
	$var->{$_} = $self->utf8_decode($obj->$_);
    }
    $var->{time} = $var->{ts};
    return $var;
}

package Kwiki::UserMessage::CGI;
use base 'Kwiki::CGI';

cgi 'run_mode';
cgi 'id';
cgi 'to';
cgi 'body';
cgi 'subject';

package Kwiki::UserMessage;

__DATA__

=head1 NAME

  Kwiki::UserMessage - Kwiki user message sub-system

=head1 SYNOPSIS

  > kwiki -add Kwiki::UserMessage

=head1 DESCRIPTION

This module is a Kwiki plugin that provide your kwiki site to have user message sub-system.
It provides a simple functionality to write message to other user, and read your message.

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__css/user_message.css__
div.user_message { width: 100%; }
table.message_list { table-layout: fixed; }
__javascript/user_message.js__

fucntion user_message_delete_confirm () {
    var agree=confirm("Are you sure you wish to delete this message ?");
    if (agree)
        return true;
    else
        return false;
}
__template/tt2/user_message_compose.html__
<h1>Compose Message</h1>
<div class="user_message">
<form action="[%script_name%]" method="POST" class="compose">
<input type="hidden" name="action" value="user_message" />
<input type="hidden" name="run_mode" value="post" />

<label>To</label>
<input type="text" name="to" />
<br />
<label>Subject</label>
<input type="text" name="subject" />
<br />


<textarea name="body"></textarea>

<hr />

<input type="submit" name="submit" value="Send" />
</form>
</div>
__template/tt2/user_message_content.html__
[%
IF hub.users.current.name;
  IF self.cgi.run_mode == "compose";
    INCLUDE "user_message_compose.html";
  ELSIF self.cgi.run_mode == "display";
    INCLUDE "user_message_display.html";
  ELSE;
    INCLUDE "user_message_list.html";
  END;
END;
%]
__template/tt2/user_message_display.html__
[% SET mid = self.cgi.id %]
[% SET m = self.load_message(mid) %]

<h1>[% m.subject %]</h1>

<dl>
  <dt>From</dt>
  <dd>[% m.sender %]</dd>
  <dt>Body</dt>
  <dd>[% m.body %]</dd>
</dl>

<a onclick="return user_message_confirm();" href="[% script_name %]?action=user_message&run_mode=delete&id=[% m.id %]">Delete This Message</a>

__template/tt2/user_message_list.html__
[% SET msg_list = self.message_list %]
<div class="user_message">

[% IF msg_list.list.size %]
<table class="message_list">
  <tr>
    <th>Delete</th>
    <th>From</th>
    <th>Subject</th>
  </tr>
[% FOREACH msg_list %]
  <tr>
    <td><a onclick="return user_message_confirm();" href="[% script_name %]?action=user_message&run_mode=delete&id=[% id %]">Delete</a></td>
    <td>[% sender %]</td>
    <td><a href="[% script_name %]?action=user_message&run_mode=display&id=[% id %]">[% subject %]</a></td>
  </tr>
[% END %]
</table>
[% ELSE %]
<p>You have no messages.</p>
[% END %]
</div>
__template/tt2/user_message_toolbar.html__
[% IF hub.users.current.name %]
<a href="[% script_name %]?action=user_message">
Read Messages
</a>
&nbsp;
<a href="[% script_name %]?action=user_message&run_mode=compose">
Write Messages
</a>
[% END %]
