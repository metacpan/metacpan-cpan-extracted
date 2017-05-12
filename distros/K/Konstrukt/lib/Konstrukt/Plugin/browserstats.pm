#FEATURE: admin: clear stats (for specific rage/for hits older than ...)
#FEATURE: graphical representation
#FEATURE: explicitly log version numbers?

=head1 NAME

Konstrukt::Plugin::browserstats - Browser statistics plugin

=head1 SYNOPSIS
	
B<Usage:>

	<!-- add browser request to the db -->
	<& browserstats / &>

or

	<!-- display the overall top browsers -->
	<& browserstats show="all" / &>

or

	<!-- display the top browsers grouped by year -->
	<!-- month and day will also work, if the data is stored in such a fine granularity -->
	<!-- the display aggregation should not be finer than the setting browserstats/aggregate -->
	<& browserstats show="year" / &>
	
B<Result:>

A table displaying the statistics, if the attribute C<show> is set. Nothing otherwise.
	
=head1 DESCRIPTION

Creates statistics about the browsers used to access your homepage.

You may simply integrate it by putting the tag into your page. See </SYNOPSIS>
for details.

=head1 CONFIGURATION

You may do some configuration in your konstrukt.settings to let the
plugin know where to get its data and which layout to use. Defaults:

	#backend
	browserstats/backend         DBI

See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::browserstats::DBI/CONFIGURATION>) for their configuration.

	#granularity
	browserstats/aggregate       all #specifies the granularity of the logs. may be all, year, month, day
	#browser classes.
	#syntax: classname1 => browsername1 browsername2, classname2 => ..., other => *
	#see HTTP::BrowserDetect for a list of browsernames
	browserstats/classes         nsold => nav2 nav3 nav4 nav4up navgold, ns6 => nav6 nav6up, firefox => firefox, opera => opera, mozilla => mozilla, ie => ie, robot => robot, other => *
	#layout
	browserstats/template_path   /templates/browserstats/
	#only count unique visitors (determined by session)
	browserstats/unique          1
	#access control
	browserstats/userlevel_view  2 #userlevel to view the stats
	browserstats/userlevel_clear 3 #userlevel to clear the logs

=cut

package Konstrukt::Plugin::browserstats;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use Konstrukt::Debug;
use Konstrukt::Parser::Node;

use HTTP::BrowserDetect;

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
	
	#set default settings
	$Konstrukt::Settings->default("browserstats/backend"         => "DBI");
	$Konstrukt::Settings->default("browserstats/template_path"   => "/templates/browserstats/");
	$Konstrukt::Settings->default("browserstats/aggregate"       => "all");
	$Konstrukt::Settings->default('browserstats/classes'         => "nsold => nav2 nav3 nav4 nav4up navgold, ns6 => nav6 nav6up, firefox => firefox, opera => opera, mozilla => mozilla, ie => ie, robot => robot, other => *");
	$Konstrukt::Settings->default('browserstats/unique'          => 1);
	$Konstrukt::Settings->default("browserstats/userlevel_view"  => 2);
	$Konstrukt::Settings->default("browserstats/userlevel_admin" => 3);
	
	#create user management objects, if needed
	if ($Konstrukt::Settings->get("browserstats/userlevel_view") or $Konstrukt::Settings->get("browserstats/userlevel_admin")) {
		#dependencies
		$self->{user_level} = use_plugin 'usermanagement::level' or return undef;
	}
	
	$self->{backend}       = use_plugin "browserstats::" . $Konstrukt::Settings->get("browserstats/backend") or return undef;
	$self->{template_path} = $Konstrukt::Settings->get('browserstats/template_path');
	
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

Prepare method

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

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

	my $attributes = $tag->{tag}->{attributes};
	if (defined $attributes->{show}) {
		#show the statistics
		$self->show_stats($attributes->{show});
	} else {
		#log a hit
		$self->hit();
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 hit

Logs a hit.

B<Parameters>:

=over

=item * $title - The title of the page to log. (optional)
If not defined, the filename of the current page will be used.

=back

=cut
sub hit {
	my ($self, $title) = @_;
	
	#only log unique visitors?
	if ($Konstrukt::Settings->get('browserstats/unique')) {
		return unless $Konstrukt::Session->activated();
		if ($Konstrukt::Session->get('browserstats/visited')) {
			#don't log again
			return;
		} else {
			#set visited flag
			$Konstrukt::Session->set('browserstats/visited', 1);
		}
	}
	
	#determine browser class
	#syntax: classname1 => browsername1 browsername2, classname2 => ...
	my @classes = split /\s*,\s*/, $Konstrukt::Settings->get('browserstats/classes');
	my $browser = new HTTP::BrowserDetect($Konstrukt::Request->header('User-Agent'));
	my $browserclass;
	foreach my $class (@classes) {
		my ($name, $keys) = split /\s*=>\s*/, $class;
		foreach my $key (split /\s+/, $keys) {
			if ($key eq "*" or eval "\$browser->$key()") {
				$browserclass = $name;
				last;
			}
		}
		last if defined $browserclass;
	}
	
	if (defined $browserclass) {
		#add log entry
		unless ($self->{backend}->hit($browserclass, $Konstrukt::Settings->get('browserstats/aggregate'))) {
			$Konstrukt::Debug->error_message("An internal error occured while logging the browser stats!") if Konstrukt::Debug::ERROR;
		}
	} else {
		#warn
		$Konstrukt::Debug->debug_message("Could not determine browser from User-Agent string '" . $Konstrukt::Request->header('User-Agent') . "'!") if Konstrukt::Debug::WARNING;
	}
}
#= /hit

=head2 show_stats

Displays the results of the browser logging.

B<Parameters>:

=over

=item * $aggregate - The range over which the hits should be aggregated.
May be C<all>, C<year>, C<month> and C<day>. Should not be finer than
the setting C<browserstats/aggregate>

=back

=cut
sub show_stats {
	my ($self, $aggregate) = @_;
	
	$aggregate ||= 'all';
	
	my $template = use_plugin 'template';
	my $level_view = $Konstrukt::Settings->get('browserstats/userlevel_view');
	
	if ($level_view > 0 and $self->{user_level}->level() >= $level_view) {
		if (my $stats = $self->{backend}->get($aggregate)) {
			if (@{$stats}) {
				#create groups of aggregation ranges
				my @groups;
				my $last_date = '';
				foreach my $entry (@{$stats}) {
					if ($entry->{date} ne $last_date) {
						#new group
						$last_date = $entry->{date};
						push @groups, { entries => [], sum => 0 };
					}
					push @{$groups[-1]->{entries}}, $entry;
					$groups[-1]->{sum} += $entry->{count};
				}
				$groups[-1]->{last_one} = 1;
				#put out groups
				foreach my $group (@groups) {
					$self->add_node($template->node("$self->{template_path}layout/group.template", { last_one => exists $group->{last_one}, date => $group->{entries}->[0]->{date}, aggregate => $aggregate, entries => [ map { $_->{share} = sprintf("%.1f%%", 100 * $_->{count} / $group->{sum}); { fields => $_ } } @{$group->{entries}} ] }));
				}
			} else {
				$self->add_node($template->node("$self->{template_path}layout/empty.template"));
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/view_failed.template"));
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/view_failed_permission_denied.template"));
	}
}
#= /show_stats

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::browserstats::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>, L<HTTP::BrowserDetect>

=cut

__DATA__

-- 8< -- textfile: layout/empty.template -- >8 --

<p>There are no browser statistics yet.</p>

-- 8< -- textfile: layout/group.template -- >8 --

<div class="browserstats group">
	<h1>
		<& perl &>
			my $date = '<+$ date $+>0000-00-00<+$ / $+>';
			my $aggregate = '<+$ aggregate $+>all<+$ / $+>';
			my %months = qw/01 January 02 February 03 March 04 April 05 May 06 June 07 July 08 August 09 September 10 October 11 November 12 December/;
			my $year  = substr($date, 0, 4);
			my $month = substr($date, 5, 2);
			my $day   = substr($date, 8, 2);
			if ($aggregate eq 'year') {
				print "Visits in $year"; 
			} elsif ($aggregate eq 'month') {
				print "Visits in the month $months{$month}, $year";
			} elsif ($aggregate eq 'day') {
				print "Visits at $months{$month} $day, $year";
			} else {
				print 'All visits';
			}
		<& / &>
	</h1>
	
	<table>
		<colgroup>
			<col width="*"   />
			<col width="70"  />
			<col width="70"  />
		</colgroup>
		<tr><th>Page</th><th>Count</th><th>Share</th></tr>
		<+@ entries @+>
		<tr>
			<td><+$ class $+>(no browserclass)<+$ / $+></td>
			<td><+$ count $+>(no count)<+$ / $+></td>
			<td><+$ share $+>(no share)<+$ / $+></td>
		</tr><+@ / @+>
	</table>
</div>

<& if condition="not '<+$ last_one $+>0<+$ / $+>'" &><hr /><& / &>

-- 8< -- textfile: messages/view_failed.template -- >8 --

<div class="browserstats failure">
	<h1>The browserstats cannot be displayed</h1>
	<p>An internal error occured!</p>
</div>

-- 8< -- textfile: messages/view_failed_permission_denied.template -- >8 --

<div class="browserstats failure">
	<h1>The browserstats cannot be displayed</h1>
	<p>The browserstats cannot be displayed, because you don't have the appropriate permissions!</p>
</div>

-- 8< -- textfile: /styles/browserstats.css -- >8 --

/* CSS definitions for the Konstrukt browserstats plugin */

/* nothing to see here */
