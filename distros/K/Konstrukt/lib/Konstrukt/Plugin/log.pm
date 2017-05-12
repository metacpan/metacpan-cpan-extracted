#FEATURE: admin: clear stats (for specific rage/for hits older than ...)

=head1 NAME

Konstrukt::Plugin::log - Konstrukt logging facilities.

=head1 SYNOPSIS
	
	<!-- add a log entry.
	     key1-5 are optional. -->
	<& log
		action="put" 
	   type="login"
	   description="user 'foo' logged in"
	   key1="some additional info"
	   key2="some additional info"
	   key3="some additional info"
	   key4="some additional info"
	   key5="some additional info"
	/ &>
	
	<!-- display log entries -->
	<& log
	   type="log type"
	   keycount="number of additional keys to display"
	   orderby="column"
	   limit="42"
	/ &>

=head1 DESCRIPTION

This module allows for logging to a given backend (like a DBI database).

Each log entry has an automatically generated timestamp and client address,
a type, which may be used to identify several loggin sources (plugin name, etc.),
a human readable description and 5 additional keys which may be up to 255 chars
long each and can be used as needed.

The perl-interface looks like this:

	my $log = use_plugin 'log';
	
	#add entry. the keys are optional
	$log->put("type", "description", "key1", "key2", "key3", "key4", "key5");
	
	#retrieve log entries of type "type" and order them by key2, key1 and key3.
	my $entries = $log->get("type", "key2, key1, key3");
	#$entries is an array reference to hash-references:
	#$entries =
		[
			{ year => 1234, month => 12, day => 12, hour => 12, minute => 12,
			  host => '192.168.0.1',
			  type => "type",
			  description => "description",
			  key1 => "key 1", key2 = "..." ... },
			...
		]
	print $entries->[3]->{description}

The Konstrukt-interface looks like this:

	<!-- add a new entry -->
	<& log action="put" type="type" description="some log entry" key1="key 1 value" key2="..." / &>
	
	<!-- print out a list in template-syntax. (default action)
	     The type attribute determines the type of the log entries to show.
	     If not defined, all types will be shown.
	     The keycount attribute determines how many keys are used in the log entries.
	     The orderby and limit attributes will be passed as-is to the DBI query. -->
	<& log type="type" keycount="3" orderby="key2, key1, key3" key1_name="foo" key2_name="bar" key3_name="baz" limit="20" / &>
	<!-- note: you may also order by the column "timestamp" -->

=head1 CONFIGURATION

You have to do some configuration in your konstrukt.settings to let the
plugin know where to get its data and which layout to use. Defaults:

	#log
	log/use              0
	log/backend          DBI
	log/template_path    /templates/log/ #path to the log templates
	log/sendmail           #send mails to this account (user@host.tld) for each new log entry
	log/sendmail_ignore    #space separated list of stings. if the subject or content of
	                       #a message contains any of these strings, no mail will be sent.
	                       #note that a substring match will be made: 'usermanagement' will
	                       #block 'usermanagement::basic' as well as 'confusermanagement::foo'.
	                       #to match a string with whitespaces, put it into doublequotes.
	#access control
	log/userlevel_view   1 #userlevel to view the logs
	log/userlevel_clear  2 #userlevel to clear the logs

Mails will be sent through L<Konstrukt::Lib/mail>.

See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::usermanagement::basic::DBI/CONFIGURATION>) for their configuration.

	#messages
	log/template_path    /log/

=cut

package Konstrukt::Plugin::log;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Debug;

=head1 METHODS

=head2 execute_again

Yes, this plugin may return dynamic nodes (i.e. template nodes).

=cut
sub execute_again {
	return 1;
}
#= /execute_again

=head2 init

Initializes this object. Sets $self->{backend} and $self->{layout_path}.
init will be called by the constructor.

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("log/use"             => 1);
	$Konstrukt::Settings->default("log/backend"         => 'DBI');
	$Konstrukt::Settings->default("log/template_path"   => '/templates/log/');
	$Konstrukt::Settings->default("log/sendmail"        => '');
	$Konstrukt::Settings->default("log/sendmail_ignore" => '');
	$Konstrukt::Settings->default("log/userlevel_view"  => 1);
	$Konstrukt::Settings->default("log/userlevel_admin" => 2);
	
	$self->{backend}       = use_plugin "log::" . $Konstrukt::Settings->get("log/backend") or return undef;
	$self->{template_path} = $Konstrukt::Settings->get('log/template_path');
	
	return 1;
}
#= /init

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($self->{template_path});
}
# /install

=head2 prepare

We cannot prepare anything as the input data may be different on each
request. The result is completely dynamic.

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	#Don't do anything beside setting the dynamic-flag
	$tag->{dynamic} = 1;#TODO: neccessary? could be detected by the parser!
	
	return undef;
}
#= /prepare

=head2 execute

All the work is done in the execute step.

=cut
sub execute {
	my ($self, $tag) = @_;

	#reset the collected nodes
	$self->reset_nodes();
	
	my $template = use_plugin 'template';
	my $level_view = $Konstrukt::Settings->get('log/userlevel_view');
	my $user_level = use_plugin 'usermanagement::level' if $level_view > 0;
	
	my $action = (exists($tag->{tag}->{attributes}->{action}) ? $tag->{tag}->{attributes}->{action} : '');
	
	#what to do?
	if ($action eq 'put') {
		#add a new entry
		unless ($self->put(
			$tag->{tag}->{attributes}->{type},
			$tag->{tag}->{attributes}->{description},
			$tag->{tag}->{attributes}->{key1},
			$tag->{tag}->{attributes}->{key2},
			$tag->{tag}->{attributes}->{key3},
			$tag->{tag}->{attributes}->{key4},
			$tag->{tag}->{attributes}->{key5}
		)) {
			$Konstrukt::Debug->error_message("Couldn't put log entry.") if Konstrukt::Debug::ERROR;
			return undef;
		}
	} else {
	#create user management objects, if needed
		if ($level_view == 0 or $user_level->level() >= $level_view) {
			my $entries;
			unless ($entries = $self->get($tag->{tag}->{attributes}->{type}, $tag->{tag}->{attributes}->{orderby}, $tag->{tag}->{attributes}->{limit})) {
				$Konstrukt::Debug->error_message("Couldn't get log entries.") if Konstrukt::Debug::ERROR;
				return undef;
			}
			my $keycount = $tag->{tag}->{attributes}->{keycount} || 0;
			if (@{$entries}) {
				#format data
				foreach my $entry (@{$entries}) {
					$entry->{description} = $Konstrukt::Lib->html_escape($entry->{description});
					map { $entry->{"key$_"} = $Konstrukt::Lib->html_escape($entry->{"key$_"}) } (1..$keycount);
					map { $entry->{$_} = sprintf "%02d", $entry->{$_} } qw/month day hour minute/;
				}
				#generate template values
				my $data = {
					fields => { map { ("key${_}_name" => $Konstrukt::Lib->html_escape($tag->{tag}->{attributes}->{"key${_}_name"}) || undef) } (1 .. $keycount) },
					lists => { list => $entries }
				};
				#put node
				$self->add_node($template->node("$self->{template_path}layout/list_${keycount}keys.template", $data));
			} else {
				#no entries
				$self->add_node($template->node("$self->{template_path}layout/list_empty.template"));
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/view_failed_permission_denied.template"));
		}
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 put

Adds a new log entry.

B<Parameters>:

=over

=item * $type - The type/source of this entry

=item * $description - A human readable description

=item * ($key1 - $key5) - Optional additional keys

=back

=cut
sub put {
	my ($self, $type, $description, @keys) = @_;
	
	if ($Konstrukt::Settings->get('log/use')) {
		my $host = $Konstrukt::Handler->{ENV}->{REMOTE_ADDR};
		
		#send email if a recipient is defined
		#and log entries of this type should be mailed
		my $mail_to = $Konstrukt::Settings->get('log/sendmail');
		#generate ignore regexp
		my @ignore = $Konstrukt::Lib->quoted_string_to_word($Konstrukt::Settings->get('log/sendmail_ignore'));
		my $ignore_regexp = "(" . join('|', map { $_ =~ s/(\W)/\\$1/g; lc $_; } @ignore) . ")";
		
		if ($mail_to and (not @ignore or ($type !~ /$ignore_regexp/i and $description !~ /$ignore_regexp/i)) and $description !~ /Konstrukt::Lib->mail/i) {
			my $subject = "Log: $type";
			my $text = "Description:\n$description\n\nHost: $host\n\nKeys:\n" . join("\n", map { defined $_ ? $_ : () } @keys);
			$Konstrukt::Lib->mail($subject, $text, $mail_to);
		}
		
		#save log entry
		return $self->{backend}->put($type, $description, $host, @keys);	
	} 
}
#= /put

=head2 get

Returns the requested log entries as an array reference of hash references.

B<Parameters>:

=over

=item * $type    - The type/source of this entry

=item * $orderby - The list will be ordered by this expression, which will be passed as-is to the SQL-query.

=back

=cut
sub get {
	my $self = shift;
	
	return $self->{backend}->get(@_) if $Konstrukt::Settings->get('log/use');
}
#= /get

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::log::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: layout/list_0keys.template -- >8 --

<table>
	<tr>
		<th>Date</th>
		<th>Host</th>
		<th>Description</th>
	</tr>
	
	<+@ list @+>
		<tr>
			<td><+$ year $+>??<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> <+$ hour $+>??<+$ / $+>:<+$ minute $+>??<+$ / $+></td>
			<td><+$ host $+>(Unknown)<+$ / $+></td>
			<td><+$ description $+>(No Description)<+$ / $+></td>
		</tr>
	<+@ / @+>
</table>

-- 8< -- textfile: layout/list_1keys.template -- >8 --

<table>
	<tr>
		<th>Date</th>
		<th>Host</th>
		<th><+$ key1_name $+>Key 1<+$ / $+></th>
		<th>Description</th>
	</tr>
	
	<+@ list @+>
		<tr>
			<td><+$ year $+>??<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> <+$ hour $+>??<+$ / $+>:<+$ minute $+>??<+$ / $+></td>
			<td><+$ host $+>(Unknown)<+$ / $+></td>
			<td><+$ key1 $+>(Empty)<+$ / $+></td>
			<td><+$ description $+>(No Description)<+$ / $+></td>
		</tr>
	<+@ / @+>
</table>

-- 8< -- textfile: layout/list_2keys.template -- >8 --

<table>
	<tr>
		<th>Date</th>
		<th>Host</th>
		<th><+$ key1_name $+>Key 1<+$ / $+></th>
		<th><+$ key2_name $+>Key 2<+$ / $+></th>
		<th>Description</th>
	</tr>
	
	<+@ list @+>
		<tr>
			<td><+$ year $+>??<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> <+$ hour $+>??<+$ / $+>:<+$ minute $+>??<+$ / $+></td>
			<td><+$ host $+>(Unknown)<+$ / $+></td>
			<td><+$ key1 $+>(Empty)<+$ / $+></td>
			<td><+$ key2 $+>(Empty)<+$ / $+></td>
			<td><+$ description $+>(No Description)<+$ / $+></td>
		</tr>
	<+@ / @+>
</table>

-- 8< -- textfile: layout/list_3keys.template -- >8 --

<table>
	<tr>
		<th>Date</th>
		<th>Host</th>
		<th><+$ key1_name $+>Key 1<+$ / $+></th>
		<th><+$ key2_name $+>Key 2<+$ / $+></th>
		<th><+$ key3_name $+>Key 3<+$ / $+></th>
		<th>Description</th>
	</tr>
	
	<+@ list @+>
		<tr>
			<td><+$ year $+>??<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> <+$ hour $+>??<+$ / $+>:<+$ minute $+>??<+$ / $+></td>
			<td><+$ host $+>(Unknown)<+$ / $+></td>
			<td><+$ key1 $+>(Empty)<+$ / $+></td>
			<td><+$ key2 $+>(Empty)<+$ / $+></td>
			<td><+$ key3 $+>(Empty)<+$ / $+></td>
			<td><+$ description $+>(No Description)<+$ / $+></td>
		</tr>
	<+@ / @+>
</table>

-- 8< -- textfile: layout/list_4keys.template -- >8 --

<table>
	<tr>
		<th>Date</th>
		<th>Host</th>
		<th><+$ key1_name $+>Key 1<+$ / $+></th>
		<th><+$ key2_name $+>Key 2<+$ / $+></th>
		<th><+$ key3_name $+>Key 3<+$ / $+></th>
		<th><+$ key4_name $+>Key 4<+$ / $+></th>
		<th>Description</th>
	</tr>
	
	<+@ list @+>
		<tr>
			<td><+$ year $+>??<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> <+$ hour $+>??<+$ / $+>:<+$ minute $+>??<+$ / $+></td>
			<td><+$ host $+>(Unknown)<+$ / $+></td>
			<td><+$ key1 $+>(Empty)<+$ / $+></td>
			<td><+$ key2 $+>(Empty)<+$ / $+></td>
			<td><+$ key3 $+>(Empty)<+$ / $+></td>
			<td><+$ key4 $+>(Empty)<+$ / $+></td>
			<td><+$ description $+>(No Description)<+$ / $+></td>
		</tr>
	<+@ / @+>
</table>

-- 8< -- textfile: layout/list_5keys.template -- >8 --

<table>
	<tr>
		<th>Date</th>
		<th>Host</th>
		<th><+$ key1_name $+>Key 1<+$ / $+></th>
		<th><+$ key2_name $+>Key 2<+$ / $+></th>
		<th><+$ key3_name $+>Key 3<+$ / $+></th>
		<th><+$ key4_name $+>Key 4<+$ / $+></th>
		<th><+$ key5_name $+>Key 5<+$ / $+></th>
		<th>Description</th>
	</tr>
	
	<+@ list @+>
		<tr>
			<td><+$ year $+>??<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> <+$ hour $+>??<+$ / $+>:<+$ minute $+>??<+$ / $+></td>
			<td><+$ host $+>(Unknown)<+$ / $+></td>
			<td><+$ key1 $+>(Empty)<+$ / $+></td>
			<td><+$ key2 $+>(Empty)<+$ / $+></td>
			<td><+$ key3 $+>(Empty)<+$ / $+></td>
			<td><+$ key4 $+>(Empty)<+$ / $+></td>
			<td><+$ key5 $+>(Empty)<+$ / $+></td>
			<td><+$ description $+>(No Description)<+$ / $+></td>
		</tr>
	<+@ / @+>
</table>

-- 8< -- textfile: layout/list_empty.template -- >8 --

<p>No entries yet.</p>

-- 8< -- textfile: messages/view_failed_permission_denied.template -- >8 --

<div class="log message failure">
	<h1>You cannot access the logs!</h1>
	<p>The log cannot be displayed, because you don't have the appropriate permissions!</p>
</div>
