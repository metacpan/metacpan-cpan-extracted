package Helios::Panoptes::JobLog;

use 5.008000;
use strict;
use warnings;
use base qw(CGI::Application);
use Data::Dumper;
use Helios::Panoptes::Helper;
use HTML::Template::Expr;

use Error qw(:try);

our $VERSION = '1.44';

=head1 NAME

Helios::Panoptes::JobLog - Helios::Panoptes extension to handle the Job Log view

=head1 DESCRIPTION

Helios::Panoptes::JobLog handles the display for the Panoptes Job Log run mode.

=cut


sub setup {
	my $self = shift;
	$self->start_mode('job_log');
	$self->run_modes(
			job_log => 'job_log',
	);
	
}


sub teardown {
	my $self = shift;
}


=head1 VIEW METHODS

These methods define code that back the particular application pages.

=head2 job_log()

The job_log() method handles the display of the Job Log page.

=cut


sub job_log {
	my $self = shift;
	my $q = $self->query();

	my $j = 0;
	my $job_id = -1;
	my $sql = "";
	my $date_parts;
	
	my @colors = qw[EFEFEF EAEAEA];

	my @funcmap = Helios::Panoptes::Helper::option_function_map();
	my %priority = Helios::Panoptes::Helper::option_priority();

	my $function = 0;
	
	if ( defined($q->param('jobid')) ) { $job_id = $q->param('jobid'); }

	return "" if $job_id == -1;
	
	$sql = "
		SELECT *
		FROM
			job
		WHERE
			jobid = ?
	";
	
	my $job_details = Helios::Panoptes::Helper::db_fetch_row($sql,$job_id);

	if($job_details->{run_after})
	{
		$date_parts = Helios::Panoptes::Helper::splitEpochDate($job_details->{run_after});
		$job_details->{run_after} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};
	}
	else
	{
		$job_details->{run_after} = '&nbsp;';
	}
	
	if($job_details->{insert_time})
	{
		$date_parts = Helios::Panoptes::Helper::splitEpochDate($job_details->{insert_time});
		$job_details->{insert_time} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};
	}
	else
	{
		$job_details->{insert_time} = '&nbsp;';
	}

	if($job_details->{grabbed_until})
	{
		$date_parts = Helios::Panoptes::Helper::splitEpochDate($job_details->{grabbed_until});
		$job_details->{grabbed_until} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};
	}
	else
	{
		$job_details->{grabbed_until} = '&nbsp;';
	}

	$job_details->{priority} = $priority{$job_details->{priority}} || $job_details->{priority};

	$sql = "
		SELECT *
		FROM
			error
		WHERE
			jobid = ?
	";
	
	my @job_error = Helios::Panoptes::Helper::db_fetch_all($sql,$job_id);

	$j = 1;	
	foreach(@job_error)
	{
		$date_parts = Helios::Panoptes::Helper::splitEpochDate($_->{error_time});
		$_->{error_time} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};

		$_->{color} = $colors[$j];
		$j=1-$j;
	}

	$sql = "
		SELECT *
		FROM
			helios_job_history_tb
		WHERE
			jobid = ?
		ORDER BY
			complete_time DESC
	";
	
	my @job_history = Helios::Panoptes::Helper::db_fetch_all($sql,$job_id);
	
	$j = 1;
	foreach(@job_history)
	{
		if($_->{complete_time})
		{
			$date_parts = Helios::Panoptes::Helper::splitEpochDate($_->{complete_time});
			$_->{complete_time} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};
		}
		else
		{
			$_->{complete_time} = '&nbsp;';
		}
	
		if($_->{grabbed_until})
		{
			$date_parts = Helios::Panoptes::Helper::splitEpochDate($_->{grabbed_until});
			$_->{grabbed_until} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};
		}
		else
		{
			$_->{grabbed_until} = '&nbsp;';
		}

		if($_->{run_after})
		{
			$date_parts = Helios::Panoptes::Helper::splitEpochDate($_->{run_after});
			$_->{run_after} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};
		}
		else
		{
			$_->{run_after} = '&nbsp;';
		}

		if($_->{insert_time})
		{
			$date_parts = Helios::Panoptes::Helper::splitEpochDate($_->{insert_time});
			$_->{insert_time} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};
		}
		else
		{
			$_->{insert_time} = '&nbsp;';
		}

		$_->{priority} = $priority{$_->{priority}} || $_->{priority};

		$_->{color} = $colors[$j];
		$j=1-$j;
	}

	$sql = "
		SELECT
			*
		FROM
			helios_log_tb
		WHERE
			jobid = ?
		ORDER BY
			log_time DESC
	";
	
	my @logs = Helios::Panoptes::Helper::db_fetch_all($sql,$job_id);
	

	# http://search.cpan.org/~saper/Sys-Syslog-0.24/Syslog.pm

	$j = 1;	
	foreach(@logs)
	{
		if($_->{log_time})
		{
			$date_parts = Helios::Panoptes::Helper::splitEpochDate($_->{log_time});
			$_->{created_at} = $date_parts->{YYYY}.'-'.$date_parts->{MM}.'-'.$date_parts->{DD}.' '.$date_parts->{HH24}.':'.$date_parts->{MI}.':'.$date_parts->{SS};
		}
		else
		{
			$_->{created_at} = '&nbsp;';
		}
		
		$_->{color} = $colors[$j];
		$_->{priority} = $priority{$_->{priority}} || $_->{priority};
		$j=1-$j;
	}

	$job_details = $job_history[0] if(!$job_details->{arg});
    my $func_details = Helios::Panoptes::Helper::db_fetch_row("SELECT funcname FROM funcmap WHERE funcid = ?", $job_details->{funcid});
    for (my $i = 0; $i < @job_history; $i++) { 
        $job_history[$i]->{funcname} = $func_details->{funcname};  
    }
    for (my $i = 0; $i < @job_error; $i++) { 
        $job_error[$i]->{funcname} = $func_details->{funcname};  
    }
    
	# this handles <params> w/newlines
	$job_details->{arg} =~ s/^.*?\</\</s;
	
	$job_details->{arg} =~ s/>/\&gt\;/g;
	$job_details->{arg} =~ s/</\&lt\;/g;
	
	my $tmpl = HTML::Template::Expr->new(filename => 'tmpl/job_log.html', die_on_bad_params => 0);
	$tmpl->param(TITLE=>"Helios - Job Log " . $job_id);
	$tmpl->param(JOBID=>$job_id);
	$tmpl->param(LOG_ENTRIES => \@logs);
	$tmpl->param(ERROR_ENTRIES => \@job_error);
	$tmpl->param(HISTORY_ENTRIES => \@job_history);
	
	$tmpl->param(JOB_ARG => $job_details->{arg});
	$tmpl->param(JOB_PRIORITY => $job_details->{priority});
	$tmpl->param(JOB_RUN_AFTER => $job_details->{run_after});
	$tmpl->param(JOB_COALESCE => $job_details->{coalesce});
	$tmpl->param(JOB_FUNCTION_NAME => $func_details->{funcname});
	$tmpl->param(JOB_UNIQUE_KEY => $job_details->{uniqkey});
	$tmpl->param(JOB_INSERT_TIME => $job_details->{insert_time});
	$tmpl->param(JOB_GRABBED_UNTIL => $job_details->{grabbed_until});

	return $tmpl->output();

}




1;
__END__

=head1 SEE ALSO

L<Helios::Panoptes>, L<Helios::Service>, L<helios.pl>, <CGI::Application>, L<HTML::Template>

=head1 AUTHOR 

Andrew Johnson, <lajandy at cpan dotorg>
Ben Kucenski, <bkucenski at ittoolbox dotcom>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-9 by CEB Toolbox, Inc.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.0 or, at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY 

This software comes with no warranty of any kind.

=cut
