package Helios::Panoptes::ErrorLog;

use 5.008000;
use strict;
use warnings;
use base qw(CGI::Application);
use Data::Dumper;
use Helios::Panoptes::Helper;
use HTML::Template::Expr;

use Error qw(:try);

our $VERSION = '1.40';

=head1 NAME

Helios::Panoptes::ErrorLog - Helios::Panoptes extension to handle the Error Log view

=head1 DESCRIPTION

Helios::Panoptes::ErrorLog handles the display and user interaction for the Panoptes Error Log 
run mode.

=cut

sub setup {
	my $self = shift;
	$self->start_mode('error_log');
	$self->run_modes(
			error_log => 'error_log',
	);
	
}


sub teardown {
	my $self = shift;
}


=head1 VIEW METHODS

These methods define code that back the particular application pages.

=head2 error_log()

The error_log() method handles the display and user interaction for the Error Log page.

=cut


sub error_log {
	my $self = shift;
	my $q = $self->query();

	my $sql = "";
	
	my $time_horizon = 300;
	my $per_page = 100;
	my $cur_page = 0;
	my @log_display = ();
	
	my @priority;
	my @priority_hash;
	
	my $message = "";
	my $search = "message";
	
	my %priority = Helios::Panoptes::Helper::option_priority();
	my %search = Helios::Panoptes::Helper::option_search();
	my %time_horizon = Helios::Panoptes::Helper::option_time_horizon();
	my %limit = Helios::Panoptes::Helper::option_limit();
	
	$search = "message" if !$search{$search};
	
	my @funcmap = Helios::Panoptes::Helper::option_function_map();

	my $function = 0;
	
	if ( defined($q->param('time')) ) { $time_horizon = $q->param('time'); }
	if ( defined($q->param('priority')) ) 
	{ 
		foreach($q->param('priority'))
		{
			if($_ > -1)
			{
				push @priority_hash, { 'option' => $_ };
				push @priority, $_;
			}
		}
	}
	if ( defined($q->param('function')) ) { $function = $q->param('function'); }
	if ( defined($q->param('message')) ) { $message = $q->param('message'); }
	if ( defined($q->param('search')) ) { $search = $q->param('search'); }
	if ( defined($q->param('page')) ) { $cur_page = $q->param('page'); }
	if ( defined($q->param('limit')) ) { $per_page = $q->param('limit'); }

	my $message_sql = "AND ?";
	my $message_value = "1";

	my $priority_sql = "AND 1";

	my $function_sql = "AND ?";
	my $function_value = "1";
	
	$message_sql = "AND $search LIKE ?" if($message);
	$message_value = "%$message%" if($message);

	$priority_sql = "AND priority IN ('" . (join "','",@priority) . "')" if(@priority);
	
	$function_sql = "AND funcid = ?" if($function);
	$function_value = $function if($function);

	$sql = "
		SELECT
			COUNT(*) AS num
		FROM
			helios_log_tb
		WHERE
			log_time >= UNIX_TIMESTAMP() - ?
			$function_sql
			$message_sql
			$priority_sql
	";

	my $total_entries = Helios::Panoptes::Helper::db_fetch_row($sql,$time_horizon, $function_value, $message_value);
	$total_entries = $total_entries->{num};

	$sql = "
		SELECT
			*
		FROM
			helios_log_tb
		WHERE
			log_time >= UNIX_TIMESTAMP() - ?
			$function_sql
			$message_sql
			$priority_sql
		ORDER BY
			log_time DESC
		LIMIT ?,?
	";
	
	my @logs = Helios::Panoptes::Helper::db_fetch_all($sql,$time_horizon, $function_value, $message_value,$cur_page * $per_page,$per_page);
	
	my @colors = qw[EFEFEF EAEAEA];
	
	# http://search.cpan.org/~saper/Sys-Syslog-0.24/Syslog.pm
	
	
	my $j = 0;
	foreach(@logs)
	{
		my $date_parts = Helios::Panoptes::Helper::splitEpochDate($_->{log_time});
		$_->{created_at} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};
		$_->{color} = $colors[$j];
		$_->{priority} = $priority{$_->{priority}} || $_->{priority};
		$j=1-$j;
	}

	my $params = $ENV{SCRIPT_NAME} . "?time=$time_horizon&function=$function&search=$search&message=$message&limit=$per_page";
	
	my $tmpl = HTML::Template::Expr->new(filename => 'tmpl/error_log.html', die_on_bad_params => 0, global_vars => 1);
	$tmpl->param(TITLE=>"Helios - Error Log");
	$tmpl->param(PRIORITY_SELECTED => \@priority_hash);
	$tmpl->param(PRIORITY_OPTIONS => Helios::Panoptes::Helper::hash_to_pair(\%priority));
	$tmpl->param(TIME => $time_horizon);
	$tmpl->param(TIME_OPTIONS => Helios::Panoptes::Helper::hash_to_pair(\%time_horizon));
	$tmpl->param(SEARCH => $search);
	$tmpl->param(SEARCH_OPTIONS =>  Helios::Panoptes::Helper::hash_to_pair(\%search,'text'));
	$tmpl->param(FUNCTION => $function);
	$tmpl->param(FUNCTION_OPTIONS => \@funcmap);
	$tmpl->param(MESSAGE => $message);
	$tmpl->param(LOG_ENTRIES => \@logs);

	$tmpl->param(PER_PAGE => $per_page);
	$tmpl->param(CUR_PAGE => $cur_page);
	$tmpl->param(LIMIT_OPTIONS =>  Helios::Panoptes::Helper::hash_to_pair(\%limit));
	$tmpl->param(PAGINATION => Helios::Panoptes::Helper::pagination($cur_page,$per_page,$total_entries,$params));
	
	foreach(@priority)
	{
		$tmpl->param('PRIORITY_' . $_,1);
	}

	return $tmpl->output();	

}




1;
__END__

=head1 SEE ALSO

L<Helios::Panoptes>, L<Helios::Service>, L<helios.pl>, <CGI::Application>, L<HTML::Template>

=head1 AUTHOR 

Andrew Johnson, <lajandy at cpan dotorg>
Ben Kucenski, <bkucenski at toolbox dotcom>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-9 by CEB Toolbox, Inc.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.0 or, at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY 

This software comes with no warranty of any kind.

=cut

