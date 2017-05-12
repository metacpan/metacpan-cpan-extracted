#TODO: better week templating?
#TODO: test DBI->get_range with special cases.
#TODO: take a look at http://search.cpan.org/~fglock/DateTime-Set-0.25/
#FEATURE: multiple data sources
#FEATURE: weekly events?
#FEATURE: option to show/export only private events
#FEATURE: vcal-export http://www.imc.org/pdi/
#FEATURE: allow events with a duration over several days?

=head1 NAME

Konstrukt::Plugin::calendar - Management of private and public calendar items

=head1 SYNOPSIS
	
	You may simply integrate it by putting
		
		<& calendar / &>
		
	somewhere in your website.
	
=head1 DESCRIPTION

This Konstrukt Plug-In provides calendar-facilities for your website.

You may simply integrate it by putting
	
	<& calendar / &>
	
somewhere in your website.

You may also create an .ihtml-file containing:
	
	<& calendar show="rss2" / &>
	
to export the latest calendar events to an RSS2 compliant file.

The RSS file will contain all events within the next X days, where X is
specified in the HTTP-request and must not exceed 31:
	
	http://domain.tld/calendar_rss2.ihtml?preview=14
	
If not specified, the range will be set to 7 (1 week).

The HTTP parameters "email" and "pass" will be used to log on the user before
retrieving the events. This will also return private events.
	
	http://domain.tld/calendar_rss2.ihtml?preview=14;email=foo@bar.baz;pass=23
	
You may also decide, whether the date and the time should be stated in the entry:
	
	http://domain.tld/calendar_rss2.ihtml?show_date=0;show_time=1

=head1 CONFIGURATION
	
You may do some configuration in your konstrukt.settings to let the
plugin know where to get its data and which layout to use. Defaults

	#backend
	calendar/backend                  DBI

See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::calendar::DBI/CONFIGURATION>) for their configuration.

	#layout
	calendar/template_path            /templates/calendar/
	#user levels
	calendar/userlevel_write          2
	calendar/userlevel_admin          3
	#rss2 export
	calendar/rss2_template            /templates/calendar/export/rss2.template
 
=cut

package Konstrukt::Plugin::calendar;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use Date::Calc qw(Week_of_Year Days_in_Month Business_to_Standard Day_of_Week Weeks_in_Year);

use Konstrukt::Debug;
use Konstrukt::Parser::Node;

=head1 METHODS

=head2 execute_again

Yes, this plugin may return dynamic nodes (i.e. template nodes).

=cut
sub execute_again {
	return 1;
}
#= /execute_again

=head2 init

Initializes this object. Sets $self->{backend} and $self->{template_path}layout/.
init will be called by the constructor.

=cut

sub init {
	my ($self) = @_;
	
	#dependencies
	$self->{user_basic}    = use_plugin 'usermanagement::basic'    or return undef;
	$self->{user_level}    = use_plugin 'usermanagement::level'    or return undef;
	$self->{user_personal} = use_plugin 'usermanagement::personal' or return undef;
	
	#set default settings
	$Konstrukt::Settings->default("calendar/backend"         => 'DBI');
	$Konstrukt::Settings->default("calendar/template_path"   => '/templates/calendar/');
	$Konstrukt::Settings->default("calendar/userlevel_write" => 2);
	$Konstrukt::Settings->default("calendar/userlevel_admin" => 3);
	$Konstrukt::Settings->default("calendar/rss2_template"   => $Konstrukt::Settings->get("calendar/template_path") . "export/rss2.template");

	$self->{backend} = use_plugin "calendar::" . $Konstrukt::Settings->get("calendar/backend") or return undef;
	$self->{template_path} = $Konstrukt::Settings->get('calendar/template_path');
	
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
	$tag->{dynamic} = 1;
	
	return undef;
}
#= /prepare

=head2 execute

All the work is done in the execute step.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;

	#reset the collected nodes
	$self->reset_nodes();

	my $show  = $tag->{tag}->{attributes}->{show} || '';
	
	if ($show eq 'rss2') {
		$self->export_rss();
	} else {
		my $action = $Konstrukt::CGI->param('action') || '';
		
		#user logged in?
		if ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('calendar/userlevel_write')) {
			#operations that are accessible to users that may write entries
			if ($action eq 'addentryshow') {
				$self->add_entry_show();
			} elsif ($action eq 'addentry') {
				$self->add_entry();
			} elsif ($action eq 'editentryshow') {
				$self->edit_entry_show();
			} elsif ($action eq 'editentry') {
				$self->edit_entry();
			} elsif ($action eq 'delentryshow') {
				$self->delete_entry_show();
			} elsif ($action eq 'delentry') {
				$self->delete_entry();
			} elsif ($action eq 'showmonth') {
				$self->show_month();
			} elsif ($action eq 'showweek') {
				$self->show_week();
			} elsif ($action eq 'showday') {
				$self->show_day();
			} elsif ($action eq 'showentry') {
				$self->show_entry();
			} elsif ($action eq 'showall') {
				$self->show_all();
			} else {
				$self->show_month();
			}
		} else {
			#operatiosn that are accessible to all visitors
			if ($action eq 'showmonth') {
				$self->show_month();
			} elsif ($action eq 'showweek') {
				$self->show_week();
			} elsif ($action eq 'showday') {
				$self->show_day();
			} elsif ($action eq 'showentry') {
				$self->show_entry();
			} elsif ($action eq 'showall') {
				$self->show_all();
			} else {
				$self->show_month();
			}
		}
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 add_entry_show

Displays the form to add an event.

=cut
sub add_entry_show {
	my ($self, $year, $month, $day) = @_;
	
	my $template = use_plugin 'template';
	my @params = map { $_ + 0 } split('-', $Konstrukt::CGI->param('date') || '');
	$year  = (defined($year)  ? $year  + 0 : 0); $year  ||= $params[0] || (localtime(time))[5] + 1900;
	$month = (defined($month) ? $month + 0 : 0); $month ||= $params[1] || (localtime(time))[4] + 1;
	$day   = (defined($day)   ? $day   + 0 : 0); $day   ||= $params[2] || (localtime(time))[3] + 0;
	$year += 1900 if $year < 1900;
	
	$self->add_node($template->node("$self->{template_path}layout/entry_add_show.template", { year => sprintf('%04d', $year), month => sprintf('%02d', $month), day => sprintf('%02d', $day) }));
}
#= /add_entry_show

=head2 add_entry

Takes the HTTP form input and adds a new event.

Displays a confirmation of the successful addition or error messages otherwise.

=cut
sub add_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_add.form");
	$form->retrieve_values('cgi');
	my $log = use_plugin 'log';
	
	if ($form->validate()) {
		my $template     = use_plugin 'template';
		
		my $year         = sprintf("%04d", $form->get_value('year'));
		my $month        = sprintf("%02d", $form->get_value('month'));
		my $day          = sprintf("%02d", $form->get_value('day'));
		my $start_hour   = sprintf("%02d", $form->get_value('start_hour'));
		my $start_minute = sprintf("%02d", $form->get_value('start_minute'));
		my $end_hour     = sprintf("%02d", $form->get_value('end_hour'));
		my $end_minute   = sprintf("%02d", $form->get_value('end_minute'));
		if ($end_hour < $start_hour or ($end_hour == $start_hour and $end_minute < $start_minute)) {
			$end_hour   = $start_hour;
			$end_minute = $start_minute;
		}
		my $description  = $form->get_value('description') || '';
		my $private      = $form->get_value('private');
		my $author       = $self->{user_basic}->id();
		if ($self->{user_level}->level() >= $Konstrukt::Settings->get('calendar/userlevel_write')) {
			if ($self->{backend}->add_entry($year, $month, $day, $start_hour, $start_minute, $end_hour, $end_minute, $description, $private, $author)) {
				#success
				my $author_name = $self->{user_basic}->email();
				$log->put(__PACKAGE__ . '->add_entry', "$author_name added a new calendar entry with the description '$description'.", $author_name);
				$self->add_node($template->node("$self->{template_path}messages/entry_add_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/entry_add_failed.template"));
			}
		} else {
			#permission denied
			$self->add_node($template->node("$self->{template_path}messages/entry_add_failed_permission_denied.template"));
		}
		$self->show_last();
	} else {
		$self->add_node($form->errors());
	}
}
#= /add_entry

=head2 edit_entry_show

Displays the form to edit an event.

=cut
sub edit_entry_show {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_edit_show.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template     = use_plugin 'template';
		
		my $id           = $form->get_value('id');
		my $entry        = $self->{backend}->get_entry($id);
		my $year         = sprintf("%04d", $entry->{year});
		my $month        = sprintf("%02d", $entry->{month});
		my $day          = sprintf("%02d", $entry->{day});
		my $start_hour   = sprintf("%02d", $entry->{start_hour});
		my $start_minute = sprintf("%02d", $entry->{start_minute});
		my $end_hour     = sprintf("%02d", $entry->{end_hour});
		my $end_minute   = sprintf("%02d", $entry->{end_minute});
		my $private      = $entry->{private};
		my $description  = $entry->{description}; #$Konstrukt::Lib->html_escape($entry->{description} || '');
		$self->add_node($template->node("$self->{template_path}layout/entry_edit_show.template", { id => $id, year => $year, month => $month, day => $day, start_hour => $start_hour, start_minute => $start_minute, end_hour => $end_hour, end_minute => $end_minute, private => $entry->{private}, description => $description }));
	} else {
		$self->add_node($form->errors());
	}
}
#= /edit_entry_show

=head2 edit_entry

Takes the HTTP form input and updates the requested event

Displays a confirmation of the successful update or error messages otherwise.

=cut
sub edit_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_edit.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template     = use_plugin 'template';
		
		my $id           = $form->get_value('id');
		my $year         = sprintf("%04d", $form->get_value('year'));
		my $month        = sprintf("%02d", $form->get_value('month'));
		my $day          = sprintf("%02d", $form->get_value('day'));
		my $start_hour   = sprintf("%02d", $form->get_value('start_hour'));
		my $start_minute = sprintf("%02d", $form->get_value('start_minute'));
		my $end_hour     = sprintf("%02d", $form->get_value('end_hour'));
		my $end_minute   = sprintf("%02d", $form->get_value('end_minute'));
		if ($end_hour < $start_hour or ($end_hour == $start_hour and $end_minute < $start_minute)) {
			$end_hour   = $start_hour;
			$end_minute = $start_minute;
		}
		my $description  = $form->get_value('description') || '';
		my $private      = $form->get_value('private');
		my $entry        = $self->{backend}->get_entry($id);
		if ($entry->{author} == $self->{user_basic}->id()) {
			if ($self->{backend}->update_entry($id, $year, $month, $day, $start_hour, $start_minute, $end_hour, $end_minute, $description, $private)) {
				#success
				$self->add_node($template->node("$self->{template_path}messages/entry_edit_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/entry_edit_failed.template"));
			}
		} else {
			#permission denied
			$self->add_node($template->node("$self->{template_path}messages/entry_edit_failed_permission_denied.template"));
		}
		$self->show_last();
	} else {
		$self->add_node($form->errors());
	}
}
#= /edit_entry

=head2 delete_entry_show

Displays the confirmation form to delete an event.

=cut
sub delete_entry_show {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_delete_show.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $event    = $self->{backend}->get_entry($form->get_value('id'));
		
		$event->{year}         = sprintf('%04d', $event->{year});
		$event->{month}        = sprintf('%02d', $event->{month});
		$event->{day}          = sprintf('%02d', $event->{day});
		$event->{start_hour}   = sprintf('%02d', $event->{start_hour});
		$event->{start_minute} = sprintf('%02d', $event->{start_minute});
		$event->{end_hour}     = sprintf('%02d', $event->{end_hour});
		$event->{end_minute}   = sprintf('%02d', $event->{end_minute});
		$event->{description}  = $Konstrukt::Lib->html_escape($event->{description});
		$self->add_node($template->node("$self->{template_path}layout/entry_delete_show.template", { id => $event->{id}, start_hour => $event->{start_hour}, start_minute => $event->{start_minute}, end_hour => $event->{end_hour}, end_minute => $event->{end_minute}, year => $event->{year}, month => $event->{month}, day => $event->{day}, description => $event->{description} }));
	} else {
		$self->add_node($form->errors());
	}
}
#= /delete_entry_show

=head2 delete_entry

Deletes the specified event.

Displays a confirmation of the successful removal or error messages otherwise.

=cut
sub delete_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_delete.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $id = $form->get_value('id');
		my $entry = $self->{backend}->get_entry($id);
		if ($entry->{author} == $self->{user_basic}->id() or $self->{user_level}->level() >= $Konstrukt::Settings->get('calendar/userlevel_admin')) {
			if ($id and $self->{backend}->delete_entry($id)) {
				#success
				$self->add_node($template->node("$self->{template_path}messages/entry_delete_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/entry_delete_failed.template"));
			}
		} else {
			#permission denied
			$self->add_node($template->node("$self->{template_path}messages/entry_delete_failed_permission_denied.template"));
		}
		$self->show_last();
	} else {
		$self->add_node($form->errors());
	}
}
#= /delete_entry

=head2 show_month

Shows an overview of a month or error messages otherwise.

Displays a confirmation of the successful removal or error messages otherwise.

B<Parameters>:

=over

=item * $year, $month - The month which should be displayed.
If not specified, the month will be received from the HTTP-parameters.
If still not specified, the current month of the system date will be taken.

Note that events that occur every day will not mark every day for an event
as this will lead into visual unclearlyness.

=back

=cut
sub show_month {
	my ($self, $year, $month) = @_;
	
	my $template = use_plugin 'template';
	
	#get date
	$month = (defined($month) ? $month + 0 : 0); $month ||= ($Konstrukt::CGI->param('month') || 0) + 0 || $Konstrukt::Session->get('calendar/current_month') || (localtime(time))[4] + 1;
	$year  = (defined($year)  ? $year  + 0 : 0); $year  ||= ($Konstrukt::CGI->param('year')  || 0) + 0 || $Konstrukt::Session->get('calendar/current_year')  || (localtime(time))[5] + 1900;
	$year += 1900 if $year < 1900;
	
	#save current date for use in other pages
	$Konstrukt::Session->set('calendar/current_year',  $year);
	$Konstrukt::Session->set('calendar/current_month', $month);
		
	#cache some user info
	my $user_id = $self->{user_basic}->id();
	
	#get localtime-compatible time of the first day of this month
	use Time::Local;
	my $time = timelocal(0, 0, 0, 1, $month - 1, $year - 1900);
	#get "day of week" of the first day in this month. convert sun = 0, sat = 6 => mon = 0, sun = 6
	my $first_day_of_week = ((localtime($time))[6] + 6) % 7;
	#calculate number of days in this month
	my $num_of_days = Days_in_Month($year, $month);
	
	#get entries
	my $events = $self->{backend}->get_month($year, $month);
	
	#generate calendar month
	my @month;
	#mark days of month where there are events
	foreach my $event (@{$events}) {
		if (!$event->{private} or ($event->{private} and ($user_id == $event->{author}))) {
			$month[$first_day_of_week + $event->{day} - 1] = 1;
		}
	}
	#put out month. collect $data to put into the template
	my $data = { year => $year, month => $month, weeks => [ {} ] };
	my $cur_week_index = -1;
	my $cur_week;
	my @localtime = localtime(time);
	my ($today_day, $today_month, $today_year) = ($localtime[3], $localtime[4] + 1, $localtime[5] + 1900);
	for (my $day = 0; $day < 42; $day++) {
		my $dow = qw/mon tue wed thu fri sat sun/[$day % 7];
		my $dom = $day - $first_day_of_week + 1;
		#break after the last day has been processed
		last if $dom > $num_of_days;
		#new week
		if ($day % 7 == 0 and $dom <= $num_of_days) {
			$data->{weeks}->[++$cur_week_index] = {};
			$cur_week = $data->{weeks}->[$cur_week_index];
			my ($week, $week_year) = Week_of_Year($year, $month, ($dom < 1 ? 1 : $dom));
			$cur_week->{week_year} = $week_year;
			$cur_week->{week} = $week;
		}
		if ($dom > 0 and $dom <= $num_of_days) {
			#put out info about this day. mark day for events, if exist
			$cur_week->{$dow} = $dom;
			$cur_week->{"${dow}_today"} = (($dom == $today_day and $month == $today_month and $year == $today_year) ? 1 : 0);
			$cur_week->{"${dow}_event"} = (defined $month[$day] ? 1 : 0);
			$cur_week->{"${dow}_date"}  = sprintf('%04d-%02d-%02d', $year, $month, $dom);
		} else {
			#"empty" day
			($cur_week->{$dow}, $cur_week->{"${dow}_today"}, $cur_week->{"${dow}_event"}, $cur_week->{"${dow}_date"})  = ('', 0, 0, '');
		}
	}
	$self->add_node($template->node("$self->{template_path}layout/month.template", $data));
	
	$Konstrukt::Session->set('calendar/last_view', "\$self->show_month($year, $month)");
}
#= /show_month

=head2 show_week

Shows an overview of a week with it's events or error messages otherwise.

B<Parameters>:

=over

=item * $year, $week - The week which should be displayed. If not specified, the
week will be received from the HTTP-parameters. If still not specified,
the current week of the system date will be taken.

=back

=cut
sub show_week {
	my ($self, $year, $week) = @_;
	
	my $template = use_plugin 'template';
	
	#get week
	$year  = (defined($year) ? $year + 0 : 0); $year ||= $Konstrukt::CGI->param('year') || $Konstrukt::Session->get('calendar/current_year') || (localtime(time))[5] + 1900;
	$week  = (defined($week) ? $week + 0 : 0); $week ||= $Konstrukt::CGI->param('week') || $Konstrukt::Session->get('calendar/current_week') || (Week_of_Year($year, (localtime(time))[4] + 1, (localtime(time))[3]))[0];
	if ($week > Weeks_in_Year($year)) {
		$week = Weeks_in_Year($year);
	}
	$year += 1900 if $year < 1900;
	#get date range for this week
	my ($start_year, $start_month, $start_day) = Business_to_Standard($year, $week, 1);
	my ($end_year  , $end_month  , $end_day  ) = Business_to_Standard($year, $week, 7);
	#warn join(', ', $start_year, $start_month, $start_day, $end_year, $end_month, $end_day);
	
	#save current date
	$Konstrukt::Session->set('calendar/current_year',  $start_year);
	$Konstrukt::Session->set('calendar/current_month', $start_month);
	$Konstrukt::Session->set('calendar/current_week',  $week);
	
	#cache some user info:
	my $user_id         = $self->{user_basic}->id();
	my $user_level      = $self->{user_level}->level();
	my $userlevel_admin = $Konstrukt::Settings->get('calendar/userlevel_admin');
	my $userlevel_write = $Konstrukt::Settings->get('calendar/userlevel_write');
	
	#get entries
	my $events;
	$events = $self->{backend}->get_range($start_year, $start_month, $start_day, $end_year, $end_month, $end_day);
	$events = $self->prepare_events($events, $start_year, $start_month, $start_day, $end_year, $end_month, $end_day);
	
	#generate week-table
	my $week_table;
	my $min_hour = 24;
	my $max_hour = -1;
	my $columns_per_day = [1, 1, 1, 1, 1, 1, 1];
	#put in events
	foreach my $event (@{$events}) {
		#get day of week
		my $dow = Day_of_Week($event->{year}, $event->{month}, $event->{day}) - 1;
		#create anonymous array for this hour if not exists
		if (!defined($week_table->[$dow]->[$event->{start_hour}])) {
			$week_table->[$dow]->[$event->{start_hour}] = [];
		}
		#relevant data:
		my $start_hour = $event->{start_hour};
		my $end_hour   = ($event->{end_minute} + 0 > 0 ? $event->{end_hour} : $event->{end_hour} - 1); #don't touch next hour, if event ends exactly at hh:00
		#calculate duration (will be used later to determine the "rowspan"):
		$event->{duration} = $end_hour - $start_hour + 1;
		#find free column. start with 0, increase column and retry, if any touched hour is
		#already blocked by an other event
		my $column = 0;
		for (my $hour = $start_hour; $hour <= $end_hour; $hour++) {
			if (defined($week_table->[$dow]->[$hour]->[$column])) {
				#try next column
				$column++;
				$hour = $start_hour - 1;
			}
		}
		#put entry
		$week_table->[$dow]->[$start_hour]->[$column] = $event;
		#block touched hours
		foreach my $hour ($start_hour + 1 .. $end_hour) {
			$week_table->[$dow]->[$hour]->[$column] = 1;
		}
		#correct columns_per_day, min_hour and max_hour if needed
		$columns_per_day->[$dow] = $column + 1 if $columns_per_day->[$dow] < $column + 1;
		$min_hour = $start_hour if $min_hour > $start_hour;
		$max_hour = $end_hour   if $max_hour < $end_hour;
	}
	#one hour space before and behind the block. show at least 8-16 'o clock
	$min_hour--    if $min_hour > 0;
	$min_hour =  8 if $min_hour > 8;
	$max_hour++    if $max_hour < 23;
	$max_hour = 16 if $max_hour < 16;
		
	#print out table
	#read template
	my $template_file = $Konstrukt::File->read_and_track("$self->{template_path}layout/week.template");
	#remove the path to this file as we only used read_and_track to add this file to the cache list
	$Konstrukt::File->pop();
	if (defined($template_file)) {
		my $week_template;
		eval($template_file);
		#Check for errors
		if ($@) {
			#Errors in eval
			chomp($@);
			$Konstrukt::Debug->error_message("Error while loading week template '$self->{template_path}layout/week.template'! $@") if Konstrukt::Debug::ERROR;
		} else {
			$self->add_node('<div class="calendar week">');
			$self->add_node($template->node("$self->{template_path}layout/week_title.template", { year => $year, week => $week }));

			my $rv = "<table>\n";
			$rv .= "\t<tr><th class=\"hour\">&nbsp;</th>" .
				join('', map {
					my $dow = $_;
					#generate date
					my ($day_year, $day_month, $day_day) = Business_to_Standard($year, $week, $dow + 1);
					my $date = $week_template->{date_format};
					$day_year = sprintf('%04d', $day_year); $day_month = sprintf('%02d', $day_month); $day_day = sprintf('%02d', $day_day);
					$date =~ s/\$year\$/$day_year/i;        $date =~ s/\$month\$/$day_month/i;         $date =~ s/\$day\$/$day_day/i;
					#return head-element
					"<th" . ($columns_per_day->[$dow] > 1 ? " colspan=\"$columns_per_day->[$dow]\"" : '') . "><a href=\"$week_template->{page}?action=showday;date=$day_year-$day_month-$day_day\">$week_template->{day_names}->[$dow]</a><div class=\"date\">$date</div></th>"
				} (0..6)) .
				"</tr>\n";
			#entries
			for (my $hour = $min_hour; $hour <= $max_hour; $hour++) {
				my $odd_even = (($hour - $min_hour) % 2 == 0 ? 'even' : 'odd');
				$rv .= "\t<tr class=\"$odd_even\"><td class=\"hour\">$hour</td>";
				foreach my $dow (0..6) {
					for (my $column = 0; $column < $columns_per_day->[$dow]; $column++) {
						my $cell = $week_table->[$dow]->[$hour]->[$column];
						my $weekend = ($dow > 4 ? ' weekend' : '');
						if (defined($cell)) {
							if (ref($cell) eq 'HASH') {
								#event
								my $may_edit   = ($cell->{author} == $user_id);
								my $may_delete = ($may_edit or $user_level >= $userlevel_admin);
								$cell->{description} = $Konstrukt::Lib->html_escape($cell->{description});
								$rv .= "<td class=\"event$weekend\"" . ($cell->{duration} > 1 ? " rowspan=\"$cell->{duration}\"" : '') . ">" .
								       "<div class=\"event time\">". sprintf('%02d:%02d-%02d:%02d', $cell->{start_hour}, $cell->{start_minute}, $cell->{end_hour}, $cell->{end_minute}) . "</div>" .
								       "<div class=\"event description\">$cell->{description}</div><div class=\"icons\">" . ($cell->{private} ? "$week_template->{img_private}" : '') . ($may_edit ? "<a href=\"$week_template->{page}?action=editentryshow;id=$cell->{id}\">$week_template->{img_edit}</a>" : '') . ($may_delete ? "<a href=\"$week_template->{page}?action=delentryshow;id=$cell->{id}\">$week_template->{img_delete}</a>" : '') . "</div></td>";
							} #else: don't print a cell
						} else {
							$rv .= "<td class=\"$weekend\">&nbsp;</td>";
						}
					}
				}
				$rv .= "</tr>\n";
			}
			$rv .= "</table>\n";
			#put week
			$self->add_node($rv);
			#foot
			$self->add_node($template->node("$self->{template_path}layout/week_select.template", { year => $year, week => $week }));
			$self->add_node('</div>');
		}
	}
	
	$Konstrukt::Session->set('calendar/last_view', "\$self->show_week($year, $week)");
}
#= /show_week

=head2 show_day

Shows an overview of a day with it's events or errpr messages otherwise.

B<Parameters>:

=over

=item * $year, $month, $day - The day which should be displayed.
If not specified, the day will be received from the HTTP-parameters.
If still not specified, the current day of the system date will be taken.

=back

=cut
sub show_day {
	my ($self, $year, $month, $day) = @_;
	
	my $template = use_plugin 'template';
	
	my $date = $Konstrukt::CGI->param('date') || '';
	$date = substr($date, 0, 10);
	my @params = map { $_ + 0 } split('-', $Konstrukt::CGI->param('date') || '');
	$year  = (defined($year)  ? $year  + 0 : 0); $year  ||= $params[0] || (localtime(time))[5] + 1900;
	$month = (defined($month) ? $month + 0 : 0); $month ||= $params[1] || (localtime(time))[4] + 1;
	$day   = (defined($day)   ? $day   + 0 : 0); $day   ||= $params[2] || (localtime(time))[3];
	$year += 1900 if $year < 1900;
	
	#save current date
	$Konstrukt::Session->set('calendar/current_year',  $year);
	$Konstrukt::Session->set('calendar/current_month', $month);
	$Konstrukt::Session->set('calendar/current_week',  Week_of_Year($year, $month, $day));
	
	#cache some user info:
	my $user_id         = $self->{user_basic}->id();
	my $user_level      = $self->{user_level}->level();
	my $userlevel_admin = $Konstrukt::Settings->get('calendar/userlevel_admin');
	my $userlevel_write = $Konstrukt::Settings->get('calendar/userlevel_write');
	
	#get entries
	my $events = $self->{backend}->get_day($year, $month, $day);
	
	#delete non-visible-entries
	for (my $i = 0; $i < @{$events}; $i++) {
		if ($events->[$i]->{private} and ($user_id != $events->[$i]->{author})) {
			splice @{$events}, $i--, 1;
		}
	}
	
	my $rv = '';
	if (@{$events}) {
		foreach my $event (@{$events}) {
			#format fields
			$event->{start_hour}   = sprintf('%02d', $event->{start_hour});
			$event->{start_minute} = sprintf('%02d', $event->{start_minute});
			$event->{end_hour}     = sprintf('%02d', $event->{end_hour});
			$event->{end_minute}   = sprintf('%02d', $event->{end_minute});
			$event->{description}  = $Konstrukt::Lib->html_escape($event->{description});
			$event->{may_edit}     = ($event->{author} == $user_id);
			$event->{may_delete}   = ($event->{may_edit} or $user_level >= $userlevel_admin);
		}
		$self->add_node($template->node("$self->{template_path}layout/day.template", { year => $year, month => $month, day => $day,  events => $events }));
	} else {
		$self->add_node($template->node("$self->{template_path}layout/day_empty.template", { year => $year, month => $month, day => $day }));
	}
	
	$self->add_entry_show($year, $month, $day) if $user_level >= $userlevel_write;
	
	$Konstrukt::Session->set('calendar/last_view', "\$self->show_day($year, $month, $day)");
}
#= /show_day

=head2 show_entry

Displays an entry.

=cut
sub show_entry {
	my ($self, $id) = @_;
	
	if (!$id) {
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/entry_show.form");
		$form->retrieve_values('cgi');
		if ($form->validate()) {
			$id = $form->get_value('id');
		} else {
			$self->add_node($form->errors());
			return;
		}
	}
	
	if ($id) {
		my $template = use_plugin 'template';
		
		#some user data
		my $user_id         = $self->{user_basic}->id();
		my $user_level      = $self->{user_level}->level();
		my $userlevel_admin = $Konstrukt::Settings->get('calendar/userlevel_admin');
		my $userlevel_write = $Konstrukt::Settings->get('calendar/userlevel_write');
		
		#format data
		my $entry             = $self->{backend}->get_entry($id);
		$entry->{year}        = sprintf("%04d", $entry->{year});
		map { $entry->{$_}    = sprintf("%02d", $entry->{$_}) } qw/month day start_hour start_minute end_hour end_minute/;
		$entry->{description} = $Konstrukt::Lib->html_escape($entry->{description});
		$entry->{may_edit}    = ($entry->{author} == $user_id);
		$entry->{may_delete}  = ($entry->{may_edit} or $user_level >= $userlevel_admin);
		
		#save last shown entry
		$Konstrukt::Session->set('calendar/last_view', "\$self->show_entry($id)");
		
		#show entry
		$self->add_node($template->node("$self->{template_path}layout/entry_show.template", { fields => $entry }));
	}
}
#= /show_entry

=head2 show_all

Shows an overview of all events or error messages otherwise.

=cut
sub show_all {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	
	#cache some user info:
	my $user_id         = $self->{user_basic}->id();
	my $user_level      = $self->{user_level}->level();
	my $userlevel_admin = $Konstrukt::Settings->get('calendar/userlevel_admin');
	my $userlevel_write = $Konstrukt::Settings->get('calendar/userlevel_write');
	
	#get entries
	my $events = $self->{backend}->get_all();
	
	#delete non-visible-entries
	for (my $i = 0; $i < @{$events}; $i++) {
		if ($events->[$i]->{private} and ($user_id != $events->[$i]->{author})) {
			splice @{$events}, $i--, 1;
		}
	}
	
	if (@{$events}) {
		foreach my $event (@{$events}) {
			#format fields
			$event->{year} = sprintf('%04d', $event->{year});
			map { $event->{$_} = sprintf('%02d', $event->{$_}) } qw/month day start_hour start_minute end_hour end_minute/;
			$event->{description}  = $Konstrukt::Lib->html_escape($event->{description});
			$event->{may_edit}   = ($event->{author} == $user_id);
			$event->{may_delete} = ($event->{may_edit} or $user_level >= $userlevel_admin);
		}
		$self->add_node($template->node("$self->{template_path}layout/all.template", { events => $events }));
	} else {
		$self->add_node($template->node("$self->{template_path}layout/all_empty.template"));
	}
	
	$Konstrukt::Session->set('calendar/last_view', "\$self->show_all()");
}
#= /show_all

=head2 show_last

Shows the last calendar view that has been saved in the session.

=cut
sub show_last {
	my ($self) = @_;
	return eval($Konstrukt::Session->get('calendar/last_view') || '$self->show_month();');
}
#= /show_last

=head2 export_rss

Generates an RSS 2.0 compliant XML file with the content from the database.

The RSS file will contain all events within the next X days, where X is
specified in the HTTP-request and must not exceed 31:
	
	http://domain.tld/calendar_rss2.ihtml?preview=14
	
If not specified, the range will be set to 7 (1 week).

The HTTP parameters "email" and "pass" will be used to log on the user before
retrieving the events. This will also return private events.

=cut
sub export_rss {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	
	#try to log on user, if parameters specified
	my ($email, $pass) = ($Konstrukt::CGI->param('email'), $Konstrukt::CGI->param('pass'));
	if ($email and $pass) {
		$self->{user_basic}->login($email, $pass);
	}
	
	#get options via HTTP-GET:
	my ($show_date, $show_time) = (($Konstrukt::CGI->param('show_date') ? 1 : 0), ($Konstrukt::CGI->param('show_time') ? 1 : 0));
	
	#get range
	my $preview = $Konstrukt::CGI->param('preview') || 7;
	my @start_time = localtime(time);
	my @end_time   = localtime(time + $preview * 86400); #days * 86400 seconds per day
	my ($start_year, $start_month, $start_day) = ($start_time[5] + 1900, $start_time[4] + 1, $start_time[3]);
	my ($end_year  , $end_month  , $end_day  ) = ($end_time[5]   + 1900, $end_time[4]   + 1, $end_time[3]  );
	my $events = $self->{backend}->get_range($start_year, $start_month, $start_day, $end_year, $end_month, $end_day);
	#prepare events for our use:
	$events = $self->prepare_events($events, $start_year, $start_month, $start_day, $end_year, $end_month, $end_day);
	#latest event first:
	$events = [reverse @{$events}];
	
	#cache some user info:
	my $user_id         = $self->{user_basic}->id();
	my $user_level      = $self->{user_level}->level();
	my $userlevel_admin = $Konstrukt::Settings->get('calendar/userlevel_admin');
	my $userlevel_write = $Konstrukt::Settings->get('calendar/userlevel_write');
	
	#collect data
	my @items;
	foreach my $entry (@{$events}) {
		#"generate" author
		my $author_data = $self->{user_personal}->data($entry->{author});
		my $firstname   = $author_data->{firstname};
		my $lastname    = $author_data->{lastname};
		my $nick        = $author_data->{nick};
		my $email       = $author_data->{email};
		my $author = '';
		if ($nick) {
			$author = $nick;
		}
		if ($firstname and $lastname) {
			$author .= ($author ? " ($firstname $lastname)" : "$firstname $lastname");
		}
		#pass data
		push @items, { fields => {
			id          => $entry->{id},
			show_date   => $show_date,
			show_time   => $show_time,
			title       => $Konstrukt::Lib->xml_escape($entry->{description}),
			author      => $Konstrukt::Lib->xml_escape($author),
			date_w3c    => $Konstrukt::Lib->date_w3c($entry->{year}, $entry->{month}, $entry->{day}, $entry->{start_hour}, $entry->{start_minute}),
			date_rfc822 => $Konstrukt::Lib->date_rfc822($entry->{year}, $entry->{month}, $entry->{day}, $entry->{start_hour}, $entry->{start_minute}),
			year        => sprintf('%04d', $entry->{year}),
			map { $_ => sprintf('%02d', $entry->{$_}) } qw/month day start_hour start_minute end_hour end_minute/,
		} };
	}
	
	#date of the feed
	my $date_w3c    = (@items ? $items[0]->{fields}->{date_w3c}    : $Konstrukt::Lib->date_w3c($start_year, $start_month, $start_day, 0, 0));
	my $date_rfc822 = (@items ? $items[0]->{fields}->{date_rfc822} : $Konstrukt::Lib->date_rfc822($start_year, $start_month, $start_day, 0, 0));
	
	#put out feed
	$self->add_node($template->node($Konstrukt::Settings->get('calendar/rss2_template'), { date_w3c => $date_w3c, date_rfc822 => $date_rfc822, items => \@items }));

	$Konstrukt::Response->header('Content-Type' => 'text/xml');
}
#
#= /export_rss

=head2 prepare_events

Prepares the passed events for later use.

Private events that don't belong to the user that is currently logged on, will
be eliminated.

Events with wildcard dates (e.g. year = 0) will be repeated within the given
date range and inserted with absolute/fixed dates.

The event list will be sorted chronologically.

Returns the prepared event list as array reference of hash references

B<Parameters>:

=over

=item * $events - Array reference of hash references containing the events

=item * $start_year, $start_month, $start_day - Start date of the date range

=item * $end_year, $end_month, $end_day - End date of the date range

=back

=cut
sub prepare_events {
	my ($self, $events, $start_year, $start_month, $start_day, $end_year, $end_month, $end_day) = @_;
	
	my $user_id = $self->{user_basic}->id();
	#prepare events:
	#delete non-visible-entries and separate events, that contain wildcards (year/month/day = 0)
	#set absolute dates for the entries (eliminate zero-wildcard-dates)
	my @wildcard;
	for (my $i = 0; $i < @{$events}; $i++) {
		if ($events->[$i]->{private} and ($user_id != $events->[$i]->{author})) {
			#not visible to current user
			splice @{$events}, $i--, 1;
		} elsif ($events->[$i]->{year} + 0 == 0 or $events->[$i]->{month} + 0 == 0 or $events->[$i]->{day} + 0 == 0) {
			#wildcard-event
			push @wildcard, $events->[$i];
			splice @{$events}, $i--, 1;
		}
	}
	
	#transform wildcard-events into "normal" events at each day
	foreach my $event (@wildcard) {
		my @years;
		if ($event->{year} + 0 == 0) {
			@years = ($start_year .. $end_year);
		} else {
			@years = ($event->{year});
		}
		#warn "years: ".join(", ", @years);
		foreach my $year (@years) {
			my @months;
			if ($event->{month} + 0 == 0) {
				if ($start_year == $end_year) {
					@months = ($start_month .. $end_month);
				} elsif ($year == $start_year) {
					@months = ($start_month .. 12);
				} elsif ($year == $end_year) {
					@months = (1 .. $end_month);
				} else {
					@months = (1 .. 12);
				}
			} else {
				@months = ($event->{month});
			}
			#warn "months: ".join(", ", @months);
			foreach my $month (@months) {
				my @days;
				if ($event->{day} + 0 == 0) {
					if ($start_year == $end_year and $start_month == $end_month) {
						@days = ($start_day .. $end_day);
					} elsif ($year == $start_year and $month == $start_month) {
						@days = ($start_day .. 31);
					} elsif ($year == $end_year and $month == $end_month) {
						@days = (1 .. $end_day);
					} else {
						@days = (1 .. 31);
					}
				} else {
					@days = ($event->{day});
				}
				#warn "days: ".join(", ", @days);
				#not we can iterate over all _possible_ dates that match the wildcards.
				#we still have to check, if the possible dates are actually covered by our range.
				foreach my $day (@days) {
					#warn sprintf('?%04d-%02d-%02d', $year, $month, $day);
					#check, if this day of month exists. also check if the event actually occurs at this day
					if ($day <= Days_in_Month($year, $month) and (
					     ($year > $start_year and $year < $end_year) or
					     (($start_year == $end_year and $year == $start_year and $month > $start_month and $month < $end_month) or ($start_year < $end_year and (($year == $start_year and $month > $start_month) or ($year == $end_year and $month < $end_month)))) or
					     (($start_year == $end_year and $year == $start_year and $start_month == $end_month and $month == $start_month and $day >= $start_day and $day <= $end_day) or ($year == $start_year and $month == $start_month and $day >= $start_day) or ($year == $end_year and $month == $end_month and $day <= $end_day)))) {
						#warn sprintf('!%04d-%02d-%02d', $year, $month, $day);
						#push new event
						push @{$events}, {id => $event->{id}, year => $year, month => $month, day => $day, description => $event->{description}, start_hour => $event->{start_hour}, start_minute => $event->{start_minute}, end_hour => $event->{end_hour}, end_minute => $event->{end_minute}, author => $event->{author}, private => $event->{private}};
					}
				}
			}
		}
	}
	
	#sort events by year, month, date, start_hour, $start_minute, $end_hour, $end_minute
	$events = [sort { ($a->{year} <=> $b->{year}) or ($a->{month} <=> $b->{month}) or ($a->{day} <=> $b->{day}) or ($a->{start_hour} <=> $b->{start_hour}) or ($a->{start_minute} <=> $b->{start_minute}) or ($a->{end_hour} <=> $b->{end_hour}) or ($a->{end_minute} <=> $b->{end_minute}); } @{$events}];
	
	return $events;
}
#= /prepare_events

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::calendar::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: export/rss2.template -- >8 --

<?xml version="1.0" encoding="ISO-8859-1"?>
<rss version="2.0" 
	xmlns:admin="http://webns.net/mvcb/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
	<channel>
		<title>gedankenkonstrukt - kalender</title>
		<link>http://your.site/</link>
		<description>some untitled calendar</description>
		<webMaster>mail@your.site</webMaster>
		<ttl>60</ttl>
		<admin:generatorAgent rdf:resource="http://your.site/?v=0.1"/>
		<admin:errorReportsTo rdf:resource="mailto:mail@your.site"/>
		<dc:language>en</dc:language>
		<dc:creator>mail@your.site</dc:creator>
		<dc:rights>Copyright 2000-2050</dc:rights>
		<dc:date><+$ date_w3c / $+></dc:date>
		<sy:updatePeriod>hourly</sy:updatePeriod>
		<sy:updateFrequency>1</sy:updateFrequency>
		<sy:updateBase>2000-01-01T12:00+00:00</sy:updateBase>
		<image>
			<url>http://your.site/gfx/calendar/logo.jpg</url>
			<title>untitled calendar</title>
			<link>http://your.site/</link>
			<width>350</width>
			<height>39</height>
		</image>
		<+@ items @+><item rdf:about="http://your.site/calender/?action=showday;date=<+$ date / $+>#<+$ id / $+>">
			<title><& if condition="<+$ show_date / $+>" &><+$ day / $+>/<+$ month / $+>/<+$ year / $+> - <& / &><& if condition="<+$ show_time / $+>" &><+$ start_hour / $+>:<+$ start_minute / $+>-<+$ end_hour / $+>:<+$ end_minute / $+>: <& / &><+$ title / $+></title>
			<link>http://your.site/calender/?action=showday;date=<+$ date / $+>#<+$ id / $+></link>
			<guid isPermaLink="true">http://your.site/calender/?action=showday;date=<+$ date / $+>#<+$ id / $+></guid>
			<pubDate><+$ date_rfc822 / $+></pubDate>
			<dc:date><+$ date_w3c / $+></dc:date>
			<dc:creator><+$ author / $+></dc:creator>
		</item><+@ / @+>
	</channel>
</rss>

-- 8< -- textfile: layout/all.template -- >8 --

<div class="calendar allevents">
	<h1>All events</h1>
	<+@ events @+>
		<div class="item">
			<h2><+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+>, <+$ start_hour $+>??<+$ / $+>:<+$ start_minute $+>??<+$ / $+> - <+$ end_hour $+>??<+$ / $+>:<+$ end_minute $+>??<+$ / $+></h2>
			<p><+$ description $+>(no description)<+$ / $+></p>
			<& if condition="<+$ may_delete $+>0<+$ / $+>" &>
				<& if condition="<+$ private $+>0<+$ / $+>" &>(private)<& / &>
				<& if condition="<+$ may_edit $+>0<+$ / $+>" &><a href="?action=editentryshow;id=<+$ id / $+>">[ edit ]</a><& / &>
				<a href="?action=delentryshow;id=<+$ id / $+>">[ delete ]</a></td></tr>
			<& / &>
			<hr />
		</div>
	<+@ / @+>
</div>

-- 8< -- textfile: layout/all_empty.template -- >8 --

<div class="calendar allevents">
	<h1>All events</h1>
	<p>No events yet</p>
</div>

-- 8< -- textfile: layout/day.template -- >8 --

<div class="calendar day">
	<h1>Day view
		<span class="date">
		(
		<& perl &>
			use Date::Calc qw/Add_Delta_Days/;
			my $year  = <+$ year  $+>0<+$ / $+>;
			my $month = <+$ month $+>0<+$ / $+>;
			my $day   = <+$ day   $+>0<+$ / $+>;
			my ($year1, $month1, $day1) = Add_Delta_Days($year, $month, $day, -1);
			my ($year2, $month2, $day2) = Add_Delta_Days($year, $month, $day,  1);
			print "<a href=\"?action=showday;date=" . sprintf('%04d-%02d-%02d', $year1, $month1, $day1) . "\">&lt;</a>\n";
			print(('(not specified)', qw/January February March April May June July August September October November December/)[$month] . " $day.,  $year\n");
			print "<a href=\"?action=showday;date=" . sprintf('%04d-%02d-%02d', $year2, $month2, $day2) . "\">&gt;</a>\n";
		<& / &>
		)
		</span>
	</h1>
	<+@ events @+>
		<div class="item">
			<h2><+$ start_hour $+>??<+$ / $+>:<+$ start_minute $+>??<+$ / $+> - <+$ end_hour $+>??<+$ / $+>:<+$ end_minute $+>??<+$ / $+></h2>
			<p><+$ description $+>(no description)<+$ / $+></p>
			<& if condition="<+$ may_delete $+>0<+$ / $+>" &>
				<& if condition="<+$ private $+>0<+$ / $+>" &>(private)<& / &>
				<& if condition="<+$ may_edit $+>0<+$ / $+>" &><a href="?action=editentryshow;id=<+$ id / $+>">[ edit ]</a><& / &>
				<a href="?action=delentryshow;id=<+$ id / $+>">[ delete ]</a></td></tr>
			<& / &>
			<hr />
		</div>
	<+@ / @+>
</div>

-- 8< -- textfile: layout/day_empty.template -- >8 --

<div class="calendar day">
	<h1>Day view
		<span class="date">
		(
		<& perl &>
			use Date::Calc qw/Add_Delta_Days/;
			my $year  = <+$ year  $+>0<+$ / $+>;
			my $month = <+$ month $+>0<+$ / $+>;
			my $day   = <+$ day   $+>0<+$ / $+>;
			my ($year1, $month1, $day1) = Add_Delta_Days($year, $month, $day, -1);
			my ($year2, $month2, $day2) = Add_Delta_Days($year, $month, $day,  1);
			print "<a href=\"?action=showday;date=" . sprintf('%04d-%02d-%02d', $year1, $month1, $day1) . "\">&lt;</a>\n";
			print(('(not specified)', qw/January February March April May June July August September October November December/)[$month] . " $day.,  $year\n");
			print "<a href=\"?action=showday;date=" . sprintf('%04d-%02d-%02d', $year2, $month2, $day2) . "\">&gt;</a>\n";
		<& / &>
		)
		</span>
	</h1>
	<p>No events at this day.</p>
</div>

-- 8< -- textfile: layout/entry_add.form -- >8 --

$form_name = 'addentry';
$form_specification =
{
	day          => { name => 'Day (0-31)'                  , minlength => 1, maxlength => 2,   match => '^([012]?\d|3[01])$' },
	month        => { name => 'Month (0-12)'                , minlength => 1, maxlength => 2,   match => '^(0?\d|1[012])$' },
	year         => { name => 'Year (number)'               , minlength => 4, maxlength => 4,   match => '^(00|19|20)\d\d$' },
	start_hour   => { name => 'Starting time: Hour (0-23)'  , minlength => 1, maxlength => 2,   match => '^(\d|[01]\d|2[0-3])$' },
	start_minute => { name => 'Starting time: Minute (1-59)', minlength => 1, maxlength => 2,   match => '^[0-5]?\d$' },
	end_hour     => { name => 'End time: Hour (0-23)'       , minlength => 1, maxlength => 2,   match => '^(\d|[01]\d|2[0-3])$' },
	end_minute   => { name => 'End time: Minute (1-59)'     , minlength => 1, maxlength => 2,   match => '^[0-5]?\d$' },
	description  => { name => 'Description (not empty)'     , minlength => 1, maxlength => 16384, match => '' },
	private      => { name => 'Private'                     , minlength => 0, maxlength => 1,   match => '' },
};

-- 8< -- textfile: layout/entry_add_show.template -- >8 --

<& formvalidator form="entry_add.form" / &>
<div class="calendar form">
	<h1>Add event</h1>
	
	<p>If an entry shall repeat every year (e.g. birthdays), you can enter "0000" as the year.</p>
	<p>If an entry shall repeat every month, you can enter "00" as the month. The same applies for the day.</p>
	<p>These options are combinable.</p>
	
	<form name="addentry" action="" method="post" onsubmit="return validateForm(document.addentry)">
		<input type="hidden" name="action" value="addentry" />
		
		<label>Date:</label>
		<input name="year"  maxlength="4" value="<+$ year $+>JJJJ<+$ / $+>" />
		<span class="inline">-</span>
		<input name="month" maxlength="2" value="<+$ month $+>MM<+$ / $+>" />
		<span class="inline">-</span>
		<input name="day"   maxlength="2" value="<+$ day $+>TT<+$ / $+>"/>
		<br />
		
		<label>Starting time:</label>
		<input name="start_hour" maxlength="2" value="08" />
		<span class="inline">:</span>
		<input name="start_minute" maxlength="2" value="00" />
		<br />
		
		<label>End time:</label>
		<input name="end_hour" maxlength="2" value="16" />
		<span class="inline">:</span>
		<input name="end_minute" maxlength="2" value="00" />
		<br />
		
		<label>Description:</label>
		<textarea name="description"></textarea>
		<br />
		
		<label>Private:</label>
		<input id="private" name="private" type="checkbox" class="checkbox" value="1" />
		<label for="private" class="checkbox">This entry is only visible for me.</label>
		<br />
		
		<label>&nbsp;</label>
		<input value="Add!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entry_delete.form -- >8 --

$form_name = 'delentry';
$form_specification =
{
	id           => { name => 'ID of the entry (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
	confirmation => { name => 'Confirmation'            , minlength => 0, maxlength => 1, match => '1' },
};

-- 8< -- textfile: layout/entry_delete_show.form -- >8 --

$form_name = 'deleteentryshow';
$form_specification =
{
	id => { name => 'ID of the entry (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/entry_delete_show.template -- >8 --

<& formvalidator form="entry_delete.form" / &>
<div class="calendar form">
	<h1>Confirmation: Delete entry</h1>
	
	<p>Shall this entry really be deleted?</p>
	
	<table class="day">
		<tr><th>Date &amp; Time</th><td><+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+>, <+$ start_hour $+>??<+$ / $+>:<+$ start_minute $+>??<+$ / $+> - <+$ end_hour $+>??<+$ / $+>:<+$ end_minute $+>??<+$ / $+></td></tr>
		<tr><th>Description    </th><td><+$ description $+>(no description)<+$ / $+></td></tr>
	</table>
	
	<form name="delentry" action="" method="post" onsubmit="return validateForm(document.delentry)">
		<input type="hidden" name="action" value="delentry" />
		<input type="hidden" name="id"     value="<+$ id / $+>" />
		
		<input id="confirmation" name="confirmation" type="checkbox" class="checkbox" value="1" />
		<label for="confirmation" class="checkbox">Yeah, kill it!</label>
		<br />
		
		<input type="submit" class="submit" value="Big red button" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entry_edit.form -- >8 --

$form_name = 'editentry';
$form_specification =
{
	id           => { name => 'ID of the entry (number)'    , minlength => 1, maxlength =>     8, match => '^\d+$' },
	day          => { name => 'Day (0-31)'                  , minlength => 1, maxlength => 2,   match => '^([012]?\d|3[01])$' },
	month        => { name => 'Month (0-12)'                , minlength => 1, maxlength => 2,   match => '^(0?\d|1[012])$' },
	year         => { name => 'Year (number)'               , minlength => 4, maxlength => 4,   match => '^(00|19|20)\d\d$' },
	start_hour   => { name => 'Starting time: Hour (0-23)'  , minlength => 1, maxlength => 2,   match => '^(\d|[01]\d|2[0-3])$' },
	start_minute => { name => 'Starting time: Minute (1-59)', minlength => 1, maxlength => 2,   match => '^[0-5]?\d$' },
	end_hour     => { name => 'End time: Hour (0-23)'       , minlength => 1, maxlength => 2,   match => '^(\d|[01]\d|2[0-3])$' },
	end_minute   => { name => 'End time: Minute (1-59)'     , minlength => 1, maxlength => 2,   match => '^[0-5]?\d$' },
	description  => { name => 'Description (not empty)'     , minlength => 1, maxlength => 16384, match => '' },
	private      => { name => 'Private'                     , minlength => 0, maxlength => 1,   match => '' },
};

-- 8< -- textfile: layout/entry_edit_show.form -- >8 --

$form_name = 'editentryshow';
$form_specification =
{
	id => { name => 'ID of the entry (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/entry_edit_show.template -- >8 --

<& formvalidator form="entry_edit.form" / &>
<div class="calendar form">
	<h1>Edit entry</h1>
	
	<p>If an entry shall repeat every year (e.g. birthdays), you can enter "0000" as the year.</p>
	<p>If an entry shall repeat every month, you can enter "00" as the month. The same applies for the day.</p>
	<p>These options are combinable.</p>
	
	<form name="editentry" action="" method="post" onsubmit="return validateForm(document.editentry)">
		<input type="hidden" name="action" value="editentry" />
		<input type="hidden" name="id"     value="<+$ id $+>0<+$ / $+>" />
		
		<label>Date:</label>
		<input name="year"  maxlength="4" value="<+$ year $+>JJJJ<+$ / $+>" />
		<span class="inline">-</span>
		<input name="month" maxlength="2" value="<+$ month $+>MM<+$ / $+>" />
		<span class="inline">-</span>
		<input name="day"   maxlength="2" value="<+$ day $+>TT<+$ / $+>"/>
		<br />
		
		<label>Starting time:</label>
		<input name="start_hour" maxlength="2" value="<+$ start_hour $+>08<+$ / $+>" />
		<span class="inline">:</span>
		<input name="start_minute" maxlength="2" value="<+$ start_minute $+>00<+$ / $+>" />
		<br />
		
		<label>End time:</label>
		<input name="end_hour" maxlength="2" value="<+$ end_hour $+>16<+$ / $+>" />
		<span class="inline">:</span>
		<input name="end_minute" maxlength="2" value="<+$ end_minute $+>00<+$ / $+>" />
		<br />
		
		<label>Description:</label>
		<textarea id="description" name="description"><+$ description / $+></textarea>
		<br />
		
		<label>Private:</label>
		<input id="private" name="private" type="checkbox" class="checkbox" value="1" <& if condition="<+$ private $+>0<+$ / $+>" &>checked="checked" <& / &>/>
		<label for="private" class="checkbox">This entry is only visible for me.</label>
		<br />
		
		<label>&nbsp;</label>
		<input value="Update!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entry_show.form -- >8 --

$form_name = 'editentryshow';
$form_specification =
{
	id => { name => 'ID of the entry (number)' , minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/entry_show.template -- >8 --

<div class="calendar entry">
	<h1>View entry</h1>
	
	<table>
		<tr>
			<th>Date:</th>
			<td><+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+></td>
		</tr>
		<tr>
			<th>Time:</th>
			<td><+$ start_hour $+>??<+$ / $+>:<+$ start_minute $+>??<+$ / $+> - <+$ end_hour $+>??<+$ / $+>:<+$ end_minute $+>??<+$ / $+></td>
		</tr>
		<tr>
			<th>Description:</th>
			<td><+$ description $+>(no description)<+$ / $+></td>
		</tr>
		
		<& if condition="<+$ may_delete $+>0<+$ / $+>" &>
		<tr>
			<td colspan="2" style="text-align: right;">
				<& if condition="<+$ private $+>0<+$ / $+>" &>(private)<& / &>
				<& if condition="<+$ may_edit $+>0<+$ / $+>" &><a href="?action=editentryshow;id=<+$ id / $+>">[ edit ]</a><& / &>
				<a href="?action=delentryshow;id=<+$ id / $+>">[ delete ]</a>
			</td>
		</tr>
		<& / &>
	</table>
</div>

-- 8< -- textfile: layout/month.template -- >8 --

<div class="calendar month">
	
	<p>Days, at which there are appointments, are shaded blue. To view the appointments of one day, or to add, edit or delete appointments, just click on the day in the calendar</p>
	<p>Additionally you can access a week view for each week by clicking on the calendar week (on the left).</p>
	
	<div class="date">
		<& perl &>
			use Date::Calc qw/Add_Delta_YM/;
			my $year  = <+$ year $+>0<+$ / $+>;
			my $month = <+$ month $+>0<+$ / $+>;
			my ($year1, $month1) = Add_Delta_YM($year, $month, 1, 0, -1);
			my ($year2, $month2) = Add_Delta_YM($year, $month, 1, 0,  1);
			print "<a href=\"?action=showmonth;year=$year1;month=$month1\">&lt;</a>\n";
			print(('(not specified)', qw/January February March April May June July August September October November December/)[$month] . ", $year\n");
			print "<a href=\"?action=showmonth;year=$year2;month=$month2\">&gt;</a>\n";
		<& / &>
	</div>
	
	<hr />
	
	<table>
		<colgroup>
			<col width="40" />
			<col width="40" />
			<col width="40" />
			<col width="40" />
			<col width="40" />
			<col width="40" />
			<col width="40" />
			<col width="40" />
		</colgroup>
		<tr><th class="week_number">CW</th><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th class="wend">Sat</th><th class="wend">Sun</th></tr>
		<+@ weeks @+>
		<tr>
			<td class="week_number"><a href="?action=showweek;year=<+$ week_year $+>????<+$ / $+>;week=<+$ week $+>??<+$ / $+>"><+$ week $+>??<+$ / $+></a></td>
			<td class="week_<+$ mon_event $+>0<+$ / $+>_<+$ mon_today $+>0<+$ / $+>"><a href="?action=showday;date=<+$ mon_date / $+>"><+$ mon / $+></a></td>
			<td class="week_<+$ tue_event $+>0<+$ / $+>_<+$ tue_today $+>0<+$ / $+>"><a href="?action=showday;date=<+$ tue_date / $+>"><+$ tue / $+></a></td>
			<td class="week_<+$ wed_event $+>0<+$ / $+>_<+$ wed_today $+>0<+$ / $+>"><a href="?action=showday;date=<+$ wed_date / $+>"><+$ wed / $+></a></td>
			<td class="week_<+$ thu_event $+>0<+$ / $+>_<+$ thu_today $+>0<+$ / $+>"><a href="?action=showday;date=<+$ thu_date / $+>"><+$ thu / $+></a></td>
			<td class="week_<+$ fri_event $+>0<+$ / $+>_<+$ fri_today $+>0<+$ / $+>"><a href="?action=showday;date=<+$ fri_date / $+>"><+$ fri / $+></a></td>
			<td class="wend_<+$ sat_event $+>0<+$ / $+>_<+$ sat_today $+>0<+$ / $+>"><a href="?action=showday;date=<+$ sat_date / $+>"><+$ sat / $+></a></td>
			<td class="wend_<+$ sun_event $+>0<+$ / $+>_<+$ sun_today $+>0<+$ / $+>"><a href="?action=showday;date=<+$ sun_date / $+>"><+$ sun / $+></a></td>
		</tr>
		<+@ / @+>
	</table>
	
	<hr />
	
	<form name="gotomonth" action="" method="get">
		<input type="hidden" name="action" value="showmonth" />
		
		<select name="month">
		<& perl &>
			my $today_month = <+$ month $+>(localtime(time))[4] + 1<+$ / $+>;
			my @months = ('(not specified)', qw/January February March April May June July August September October November December/);
			foreach my $month (1 .. 12) {
				print "				<option value=\"$month\"" . ($month == $today_month ? " selected=\"selected\"" : '') . ">$months[$month]</option>\n";
			}
		<& / &>
		</select>
		
		<select name="year">
		<& perl &>
			my $today_year = <+$ year $+>(localtime(time))[5] + 1900<+$ / $+>;
			foreach my $year (($today_year - 3) .. ($today_year + 6)) {
				print "				<option value=\"$year\"" . ($year == $today_year ? " selected=\"selected\"" : '') . ">$year</option>\n";
			}
		<& / &>
		</select>
		
		<input value="Go!" type="submit" />
	</form>
	
</div>

-- 8< -- textfile: layout/week.template -- >8 --

$week_template =
	{
		day_names   => [qw(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)],
		date_format => '$year$-$month$-$day$',
		page        => '',
		img_private => '(private) ',
		img_edit    => '[ edit ] ',
		img_delete  => '[ delete ] ',
	}

-- 8< -- textfile: layout/week_select.template -- >8 --

	<hr />
	
	<form name="gotoweek" action="" method="get">
		<input type="hidden" name="action" value="showweek" />
		
		<select name="year">
		<& perl &>
			my $today_year = <+$ year $+>(localtime(time))[5] + 1900<+$ / $+>;
			foreach my $year (($today_year - 3) .. ($today_year + 6)) {
				print "				<option value=\"$year\"" . ($year == $today_year ? " selected=\"selected\"" : '') . ">$year</option>\n";
			}
		<& / &>
		</select>
		
		<select name="week">
		<& perl &>
			my $today_week = <+$ week $+>(localtime(time))[4] + 1<+$ / $+>;
			foreach my $week (1 .. 53) {
				print "				<option value=\"$week\"" . ($week == $today_week ? " selected=\"selected\"" : '') . ">$week</option>\n";
			}
		<& / &>
		</select>
		
		<input value="Go!" type="submit" />
	</form>
	
	<hr />

-- 8< -- textfile: layout/week_title.template -- >8 --

<div class="weektitle">
	<& perl &>
		use Date::Calc qw/Business_to_Standard Standard_to_Business Weeks_in_Year Add_Delta_Days/;
		my $calyear = <+$ year $+>0<+$ / $+>;
		my $calweek = <+$ week $+>0<+$ / $+>;
		my ($year, $month, $day) = Business_to_Standard($calyear, $calweek, 1);
		my ($year1, $week1) = Standard_to_Business(Add_Delta_Days($year, $month, $day, -7));
		my ($year2, $week2) = Standard_to_Business(Add_Delta_Days($year, $month, $day,  7));
		print "<a href=\"?action=showweek;year=$year1;week=$week1\">&lt;</a>\n";
		print "CW $calweek $calyear\n";
		print "<a href=\"?action=showweek;year=$year2;week=$week2\">&gt;</a>\n";
	<& / &>
</div>

-- 8< -- textfile: messages/entry_add_failed.template -- >8 --

<div class="calendar message failure">
	<h1>Entry not added</h1>
	<p>An internal error occured while adding the entry.</p>
</div>

-- 8< -- textfile: messages/entry_add_failed_permission_denied.template -- >8 --

<div class="calendar message failure">
	<h1>Entry not added</h1>
	<p>The entry has not been added, because you don't have the appropriate permissions!</p>
</div>

-- 8< -- textfile: messages/entry_add_successful.template -- >8 --

<div class="calendar message success">
	<h1>Entry added</h1>
	<p>The entry has been added successfully!</p>
</div>

-- 8< -- textfile: messages/entry_delete_failed.template -- >8 --

<div class="calendar message failure">
	<h1>Entry not deleted</h1>
	<p>An internal error occurred while deleting the entry.</p>
</div>

-- 8< -- textfile: messages/entry_delete_failed_permission_denied.template -- >8 --

<div class="calendar message failure">
	<h1>Entry not deleted</h1>
	<p>The entry has not been deleted, because only the author of this entry or an administrator can delete it!</p>
</div>

-- 8< -- textfile: messages/entry_delete_successful.template -- >8 --

<div class="calendar message success">
	<h1>Entry deleted</h1>
	<p>The entry has been deleted successfully!</p>
</div>

-- 8< -- textfile: messages/entry_edit_failed.template -- >8 --

<div class="calendar message failure">
	<h1>Entry not updated</h1>
	<p>An internal error occured while updating the entry.</p>
</div>

-- 8< -- textfile: messages/entry_edit_failed_permission_denied.template -- >8 --

<div class="calendar message failure">
	<h1>Entry not updated</h1>
	<p>The entry has not been updated, because only the author of this entry can update it!</p>
</div>

-- 8< -- textfile: messages/entry_edit_successful.template -- >8 --

<div class="calendar message success">
	<h1>Entry updated</h1>
	<p>The entry has been updated successfully!</p>
</div>

-- 8< -- textfile: /calendar/rss2/index.html -- >8 --

<& calendar show="rss2" / &>

-- 8< -- textfile: /calendar/rss2/info/index.html -- >8 --

<html>
	<head>
		<title>calendar rss2 info</title>
	</head>
	<body>
		<h1>About the RSS 2.0 export functionality of the calendar</h1>

		<p>This calendar can be exported as an <strong>RSS 2.0-Feed</strong>. You can poll the upcoming events as an RSS feed and integrate them easily into your RSS reader (mail client, browser, ext. program, ...).</p>
		<p>The <strong>URL</strong> pointing to the feed is:</p>
		<p><a href="/calendar/rss2/">http://your.site/calendar/rss2/</a>.</p>
		<p>You can pass some <strong>options</strong> to the feed. So you can define, how far in the future the polled events may be:</p>
		<p><a href="/calendar/rss2/?preview=14">http://your.site/calendar/rss2/?preview=14</a></p>
		<p>Where 14 is the <strong>number of days</strong>. The number of days is limited to 31. The default is 7 days.</p>
		<p>As you can create private appointments, you may want to specify your <strong>username and password</strong>, so that your private appointments also get exported:</p>
		<p><a href="/calendar/rss2/?email=email@server.tld;pass=password">http://your.site/calendar/rss2/?email=email@server.tld;pass=password</a></p>
		<p>Where "email@server.tld" is your email address, with which you are registered on this site, and "password" must be substituted by your login password.</p>
		<p>These option can be <strong>combined</strong>:</p>
		<p><a href="/calendar/rss2/?preview=14;email=email@server.tld;pass=password">http://your.site/kalender/rss2/?preview=14;email=email@server.tld;pass=passwort</a></p>
		<p>That's it :)</p>
		
	</body>
</html>

-- 8< -- binaryfile: /images/calendar/rss2.gif -- >8 --

R0lGODlhMgAPALMAAGZmZv9mAP///4mOeQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAACwAAAAAMgAPAAAEexDISau9OFvBu/9gKI6dJARoqq4sKgxwLM/0IJhtnr91T9+Ak26Y4vmO
NpyLo+oUmUVZ52eUKgPC7Eq4rVV5VRiQ63w2ua4ZRy3+XU9o17Yp9bbVbzkWuo9/p0ZrbkFEhWFI
g3GFLIeIVoSLOo2OYiYkl5iZQBqcnZ4TEQA7

-- 8< -- textfile: /styles/calendar.css -- >8 --

/* CSS definitions for the Konstrukt calendar plugin */

img.calendar_icon {
	vertical-align: middle;
}


/* day view */

div.calendar.day div.date {
	font-size: 1.4em;
	font-weight: bold;
	margin: 20px 0 20px 0;
}

div.calendar.day h1 span.date {
	font-size: 0.9em;
}


/* month view */

div.calendar.month table {
	margin: 2px auto 2px auto;
	width: 400px;
}

div.calendar.month table th, div.calendar.month table td {
	text-align: right;
	vertical-align: middle;
	padding: 10px;
}

div.calendar.month table th.wend {
	background-color: #bfe3ff;
}

/* highlight weekend days */
div.calendar.month table td.wend_0_0,
div.calendar.month table td.wend_0_1,
div.calendar.month table td.wend_1_0,
div.calendar.month table td.wend_1_1 {
	background-color: #e8f5ff;
}

/* number code: event (0|1), today (0|1) */
/* outline today */
div.calendar.month table td.week_0_1,
div.calendar.month table td.week_1_1,
div.calendar.month table td.wend_0_1,
div.calendar.month table td.wend_1_1 {
	border: 3px solid #6696D1;
}

/* highlight events */
div.calendar.month table td.week_1_0,
div.calendar.month table td.week_1_1,
div.calendar.month table td.wend_1_0,
div.calendar.month table td.wend_1_1 {
	background-color: #b2d5ff;
	font-weight: bold;
}

/* highlight calendar week numbers */
div.calendar.month table .week_number, div.calendar.month table .week_number, div.calendar.month table td.week_number a {
	background-color: transparent;
	font-style: italic;
	color: #999999;
}

div.calendar.month hr {
	width: 400px;
	text-align: center; /* alignment for iE */
	margin: 8px auto 8px auto;
}

div.calendar.month div.date {
	text-align: center;
	font-size: 1.6em;
	font-weight: bold;
}

div.calendar.month form {
	text-align: center;
}
div.calendar.month form input, div.calendar.month form select {
	float: none;
}


/* week view */

div.calendar.week table {
	width: 100%;
}

div.calendar.week table td {
	vertical-align: top;
}

div.calendar.week table tr.odd td {
	background-color: #e8f5ff;
}
div.calendar.week table tr.odd td.weekend {
	background-color: #d1ebff;
}

div.calendar.week table tr td.event {
	background-color: #b2d5ff;
}

div.calendar.week table tr td div.event.time {
	font-style: italic;
	margin-bottom: 5px;
}

div.calendar.week table div.icons {
	text-align: right;
	margin-top: 10px;
}

div.calendar.week hr {
	width: 400px;
	text-align: center; /* alignment for iE */
	margin: 8px auto 8px auto;
}

div.calendar div.weektitle {
	text-align: center;
	font-size: 1.6em;
	font-weight: bold;
}

div.calendar.week form {
	text-align: center;
}
div.calendar.week form input, div.calendar.week form select {
	float: none;
}
