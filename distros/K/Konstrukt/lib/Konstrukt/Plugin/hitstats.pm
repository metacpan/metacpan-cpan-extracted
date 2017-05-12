#FEATURE: admin: clear stats (for specific rage/for hits older than ...)
#FEATURE: graphical representation

=head1 NAME

Konstrukt::Plugin::hitstats - Hit statistics plugin

=head1 SYNOPSIS

	<!-- count hit. use the specified title -->
	<& hitstats title="some page" / &>
	
	<!-- count hit. use the current filename as title -->
	<& hitstats / &>
	
	<!-- display the overall top sites -->
	<& hitstats show="all" / &>
	
	<!-- display the top sites grouped by year -->
	<!-- month and day will also work, if the data is stored in such a fine granularity -->
	<!-- the display aggregation should not be finer than the setting hitstats/aggregate -->
	<& hitstats show="year" / &>
	
	<!-- only display the top 20 sites -->
	<& hitstats show="all" limit="20" / &>
	
	<!-- with optional title attribute  -->
	<& hitstats show="counter" title="some page" / &>
	<!-- display a counter and use the filename of the current page as the title -->
	<& hitstats show="counter" / &>

=head1 DESCRIPTION

Creates statistics about the number of hits of your homepage.

You may simply integrate it by putting the tag into your page. See </SYNOPSIS>
for details.

=head1 CONFIGURATION

You may do some configuration in your konstrukt.settings to let the
plugin know where to get its data and which layout to use. Defaults:

	#backend
	hitstats/backend              DBI

See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::hitstats::DBI/CONFIGURATION>) for their configuration.

	#granularity
	hitstats/aggregate            all #specifies the granularity of the logs. may be all, year, month, day
	#layout
	hitstats/template_path        /templates/hitstats/
	#only count unique visitors per page (determined by session)
	hitstats/unique               0
	#don't count hits by robots
	hitstats/ignore_robots        1
	#access control
	hitstats/userlevel_view       2 #userlevel to view the stats
	hitstats/userlevel_clear      3 #userlevel to clear the logs

=cut

package Konstrukt::Plugin::hitstats;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

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
	
	#set default settings
	$Konstrukt::Settings->default("hitstats/backend"         => "DBI");
	$Konstrukt::Settings->default("hitstats/template_path"   => "/templates/hitstats/");
	$Konstrukt::Settings->default("hitstats/aggregate"       => "all");
	$Konstrukt::Settings->default("hitstats/unique"          => 0);
	$Konstrukt::Settings->default("hitstats/ignore_robots"   => 1);
	$Konstrukt::Settings->default("hitstats/userlevel_view"  => 2);
	$Konstrukt::Settings->default("hitstats/userlevel_admin" => 3);
	
	#create user management objects, if needed
	if ($Konstrukt::Settings->get("hitstats/userlevel_view") or $Konstrukt::Settings->get("hitstats/userlevel_admin")) {
		#dependencies
		$self->{user_level} = use_plugin 'usermanagement::level' or return undef;
	}
	
	$self->{backend}       = use_plugin "hitstats::" . $Konstrukt::Settings->get("hitstats/backend") or return undef;
	$self->{template_path} = $Konstrukt::Settings->get('hitstats/template_path');
	
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
		if ($attributes->{show} eq 'counter') {
			#show a counter
			$self->show_counter($attributes->{title});
		} else {
			#show the statistics
			$self->show_stats($attributes->{show}, $attributes->{limit});
		}
	} else {
		#log a hit
		$self->hit($attributes->{title});
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
	
	#ignore robots?
	if ($Konstrukt::Settings->get('hitstats/ignore_robots')) {
		require HTTP::BrowserDetect;
		my $browser = new HTTP::BrowserDetect($Konstrukt::Request->header('User-Agent'));
		return if $browser->robot();
	}
	
	#only log unique visitors?
	if ($Konstrukt::Settings->get('hitstats/unique')) {
		return unless $Konstrukt::Session->activated();
		if ($Konstrukt::Session->get('hitstats/visited/' . $title)) {
			#don't log again
			return;
		} else {
			#set visited flag for this page
			$Konstrukt::Session->set('hitstats/visited/' . $title, 1);
		}
	}
	
	$title = $Konstrukt::Handler->{filename} unless $title;
	unless ($self->{backend}->hit($title, $Konstrukt::Settings->get('hitstats/aggregate'))) {
		$Konstrukt::Debug->error_message("An internal error occured while logging the hit for the page '$title'!") if Konstrukt::Debug::ERROR;
	}
}
#= /hit

=head2 show_stats

Displays the results of the hit logging.

B<Parameters>:

=over

=item * $aggregate - The range over which the hits should be aggregated.
May be C<all>, C<year>, C<month> and C<day>. Should not be finer than
the setting C<hitstats/aggregate>

=item * $limit - Max. number of returned entries.

=back

=cut
sub show_stats {
	my ($self, $aggregate, $limit) = @_;
	
	$aggregate ||= 'all';
	$limit ||= 0;
	
	my $template = use_plugin 'template';
	my $level_view = $Konstrukt::Settings->get('hitstats/userlevel_view');
	
	if ($level_view > 0 and $self->{user_level}->level() >= $level_view) {
		if (my $stats = $self->{backend}->get($aggregate, $limit)) {
			if (@{$stats}) {
				#create groups of aggregation ranges
				my @groups;
				my $last_date = '';
				foreach my $entry (@{$stats}) {
					if ($entry->{date} ne $last_date) {
						last if $limit and @groups == $limit;
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

=head2 show_counter

Displays a simple counter for the specified page.

B<Parameters>:

=over

=item * $title - The title of the page

=back

=cut
sub show_counter {
	my ($self, $title) = @_;
	
	my $template = use_plugin 'template';
	$title = $Konstrukt::Handler->{filename} unless $title;
	
	my $count = $self->{backend}->get_count($title) || 0;
	$self->add_node($template->node("$self->{template_path}layout/counter.template", { count => $count }));
}
#= /show_counter

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::hitstats::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: layout/counter.template -- >8 --

<p style="text-align: center">Hits: <+$ count $+>(Counter not available)<+$ / $+></p>

-- 8< -- textfile: layout/empty.template -- >8 --

<p>No hit statistics available yet.</p>

-- 8< -- textfile: layout/group.template -- >8 --

<div class="hitstats group">
	<h1>
		<& perl &>
			my $date = '<+$ date $+>0000-00-00<+$ / $+>';
			my $aggregate = '<+$ aggregate $+>all<+$ / $+>';
			my %months = qw/01 January 02 February 03 March 04 April 05 May 06 June 07 July 08 August 09 September 10 October 11 November 12 December/;
			if ($aggregate eq 'year') {
				print 'Visits in year ' . substr($date, 0, 4);
			} elsif ($aggregate eq 'month') {
				print 'Visits in month ' . $months{substr($date, 5, 2)} . ' ' . substr($date, 0, 4);
			} elsif ($aggregate eq 'day') {
				print 'Visits on ' . $months{substr($date, 5, 2)} . substr($date, 8, 2) . '., ' . substr($date, 0, 4);
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
			<td><+$ title $+>(no title)<+$ / $+></td>
			<td><+$ count $+>(no count)<+$ / $+></td>
			<td><+$ share $+>(no share)<+$ / $+></td>
		</tr>
		<+@ / @+>
	</table>
</div>
<& if condition="not '<+$ last_one $+>0<+$ / $+>'" &><hr /><& / &>

-- 8< -- textfile: messages/view_failed.template -- >8 --

<div class="hitstats message failure">
	<h1>Hit statistics cannot be shown</h1>
	<p>An internal error occurred!</p>
</div>

-- 8< -- textfile: messages/view_failed_permission_denied.template -- >8 --

<div class="hitstats message failure">
	<h1>Hit statistics cannot be shown</h1>
	<p>The hit statistics cannot be shown, because you don't have the appropriate permissions!</p>
</div>

-- 8< -- textfile: /styles/hitstats.css -- >8 --

/* CSS definitions for the Konstrukt hitstats plugin */

/* nothing to see here */
