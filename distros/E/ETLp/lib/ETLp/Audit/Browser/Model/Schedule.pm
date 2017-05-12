package ETLp::Audit::Browser::Model::Schedule;

use MooseX::Declare;

=head1 NAME

ETLp::Audit::Browser::Model::Schedule - Model Class for interacting
with Runtime Process Audit Schedules

=head1 SYNOPSIS

    use ETLp::Audit::Browser::Model::Schedule;
    
    my $model = ETLp::Audit::Browser::Model::Schedule->new();
    my $processes = $model->get_schedules(
        page         => 1,
        config_name  => 'ApacheLogs',
        section_name => 'NZServers'
    );

=cut

class ETLp::Audit::Browser::Model::Schedule with
    (ETLp::Role::Config, ETLp::Role::Schema, ETLp::Role::Audit,
     ETLp::Role::Browser) {        
    
    use Data::Dumper;
    use Try::Tiny;
    use Text::Wrapper;
    use Config::General qw(ParseConfig);
    use File::Copy;
    use File::Basename;
    use DateTime;
    
=head1 METHODS

=head2 get_schedules

Returns a resultset on the ep_schedule table, based on the supplied criteria.
It will grab 10 rows at a time, and is ordered by date_updated descending

=head3 Parameters
    
    * page. Optional, Integer. The page you wish to return. Defaults
      to 1.
    * config_name: Optional. The name of the configuration file
    * section_name. The name of the fection in the configuration file
    
=head3 Returns

    * A DBIx::Class resultset

=cut

    method get_schedules(HashRef $args) {
        my $page     = $args->{page} || 1;
        my $criteria = {};
        my $filter   = {
            join     => {'section' => ['config']},
            prefetch => {'section' => ['config']},
            order_by => ['config_name', 'section_name'],
        };
    
        unless ($args->{no_paging}) {
            $filter->{page} = $page;
            $filter->{rows} = 10;
        }
    
        # Add the filter if one was supplied
        if ($args->{config_name}) {
            $criteria->{'config_name'} = $args->{config_name};
        }
    
        if ($args->{section_name}) {
            $criteria->{'section_name'} = $args->{section_name};
        }
    
        if (defined($args->{status}) && ($args->{status} ne '')) {
            $criteria->{status} = $args->{status};
        }
    
        my $schedules = $self->EtlpSchedule->search($criteria, $filter);
        return $schedules;
    }

=head2 get_schedule_details

Returns an array ref consisting of the main schedule and associated
time componnets

=head3 Parameters
    
    * page. Optional, Integer. The page you wish to return. Defaults
      to 1.
    * config_name: Optional. The name of the configuration file
    * section_name. The name of the fection in the configuration file
    * status. Optional. (1 = active, 0 = inactive)
    
=head3 Returns

An array ref of schedule details:

    * schedule_id
    * minutes (cron format)
    * hours (cron format)
    * dom - day of month (cron format)
    * days - days of the week (cron format)
    * month - 1-12
    * description - description of the schedule
    * comment - any comment provided by the suer who edited the schedule
    * status (1 = active, 0 = inactive)
    * config_name - name of the configuration tghe schedule is processing
    * section - the section inside the configuration file

=cut

    method get_schedule_details(HashRef $args) {
        my $schedule_details;
        my @schedules;
        my $schedules = $self->get_schedules($args);
    
        # Loop through each shedule and add the time components to the returned
        # records
        while (my $schedule = $schedules->next) {
            my $schedule_id = $schedule->schedule_id;
            my $minutes     = $self->get_contracted_minutes($schedule_id);
            my $hours       = $self->get_contracted_hours($schedule_id);
            my $doms        = $self->get_contracted_doms($schedule_id);
            my $day_ids     = $self->get_contracted_cron_dows($schedule_id);
            my $days      = join(', ', @{$self->get_day_names($schedule_id)}) || '';
            my $month_rec = $self->get_schedule_month($schedule_id) || '';
            my $month     = ($month_rec) ? $month_rec->ep_month->month_name : '';
            my $month_id  = ($month_rec) ? $month_rec->month_id : '';
    
            push @schedules,
              {
                schedule_id  => $schedule_id,
                minutes      => $minutes,
                hours        => $hours,
                doms         => $doms,
                day_ids      => $day_ids,
                days         => $days,
                month        => $month,
                month_id     => $month_id,
                description  => $schedule->schedule_description,
                comment      => $schedule->schedule_comment,
                status       => $schedule->status,
                config_name  => $schedule->ep_section->ep_config->config_name,
                section_name => $schedule->ep_section->section_name,
              };
        }
    
        $self->logger->debug(Dumper(\@schedules));
        return \@schedules;
    }
   
=head2 get_day_names

Get the day names for a schedule

=head3 Parameters
 
    * schedule_id. Optional. The schedule's key
    
=head3 Returns

    * An array ref of day names, in day-of-week order

=cut

    method get_day_names(Int $schedule_id) {
        my @days;
    
        foreach my $day (
            $self->EtlpDayOfWeek->search(
                {schedule_id => $schedule_id},
                {
                    join     => 'ep_schedule_day_of_weeks',
                    order_by => 'dow_id'
                }
            )->all
          )
        {
            ;
            push @days, $day->day_name;
        }
    
        return \@days;
    }

=head2 get_schedule

Returns the schedule withe the supplied id

=head3 Parameters
 
    * schedule_id. Optional.  1
    
=head3 Returns

    * A DBIx::Class row object

=cut

    method get_schedule(Maybe[Int] $schedule_id?) {
        return $self->EtlpSchedule->find($schedule_id);
    }
    
=head2 get_months

Returns all of the ep_months records

=head3 Parameters

None
    
=head3 Returns

    * An Array of DBIx::Class row objects

=cut

    method get_months {
        my @months = $self->EtlpMonth->search(undef, {order_by => 'month_id'})->all;
        unshift @months, {month_id => undef, month_name => undef};
        return \@months;
    }
    
=head2 get_dows

Gets all of the ep_days_of_month records

=head3 Parameters

None
    
=head3 Returns

    * An Array of DBIx::Class row objects

=cut

    method get_dows {
        return $self->EtlpDayOfWeek->search(undef, {order_by => 'dow_id'});
    }
    
=head2 get_schedule_month

Gets the month that the job is scheduled to run for

=head3 Parameters

    * schedule_id. Integer
    
=head3 Returns

    * A EtlpScheduleMonth resultset row

=cut
    
    method get_schedule_month(Maybe[Int] $schedule_id?) {
        return $self->EtlpScheduleMonth->search({schedule_id => $schedule_id},
            {order_by => 'month_id'})->first;
    }
    
=head2 get_schedule_dows

Gets all of the days of the week that the job is scheduled to run for

=head3 Parameters

    * schedule_id. Integer
    
=head3 Returns

    * A hashref, where the keys are the dow_ids that are scheduled

=cut
    
    method get_schedule_dows(Maybe[Int] $schedule_id?) {
        my %dow;
    
        my $dow_rs =
          $self->EtlpScheduleDayOfWeek->search({schedule_id => $schedule_id},
            {order_by => 'dow_id'});
    
        while (my $dow_row = $dow_rs->next) {
            my $dow_id = $dow_row->dow_id;
            $dow{$dow_id}++;
        }
    
        return \%dow;
    }
    
=head2 get_schedule_cron_dows

Gets all of the days of the week that the job is scheduled to run for.
The days are indexed by the cron day ids (0-6 = Sun - Sat) not the
scheduled day of week surrogate key

=head3 Parameters

    * schedule_id. Integer
    
=head3 Returns

    * A hashref, where the keys are the dow_ids that are scheduled

=cut

    method get_schedule_cron_dows(Maybe[Int] $schedule_id?) {
        my %dow;
    
        my $dow_rs = $self->EtlpScheduleDayOfWeek->search(
            {schedule_id => $schedule_id},
            {
                join     => 'ep_day_of_week',
                order_by => 'cron_day_id'
            }
        );
    
        while (my $dow_row = $dow_rs->next) {
            my $dow_id = $dow_row->ep_day_of_week->cron_day_id;
            $dow{$dow_id}++;
        }
    
        return \%dow;
    }

=head2 get_schedule_doms

Gets all of the days of the month that the job is scheduled to run for

=head3 Parameters

    * schedule_id. Integer
    
=head3 Returns

    * A EtlpScheduleDayOfMonth resultset

=cut

    method get_schedule_doms(Maybe[Int] $schedule_id?) {
        return $self->EtlpScheduleDayOfMonth->search({schedule_id => $schedule_id},
            {order_by => 'schedule_dom'});
    }
    
=head2 get_schedule_minutes

Gets all of the minutes that the job is scheduled to run for

=head3 Parameters

    * schedule_id. Integer
    
=head3 Returns

    * A EtlpScheduleMinute resultset

=cut

    method get_schedule_minutes(Maybe[Int] $schedule_id?) {
        return $self->EtlpScheduleMinute->search({schedule_id => $schedule_id},
            {order_by => 'schedule_minute'});
    }
    
=head2 get_schedule_hours

Gets all of the hours that the job is scheduled to run for

=head3 Parameters

    * schedule_id. Integer
    
=head3 Returns

    * A EtlpScheduleHour resultset

=cut

    method get_schedule_hours(Maybe[Int] $schedule_id?) {
        return $self->EtlpScheduleHour->search({schedule_id => $schedule_id},
            {order_by => 'schedule_hour'});
    }

=head2 expand_entries

Takes section of cron entries for a given element (e.g. minutes), and
expands the into an array ref. If the section contains a range then
these are expanded into indvidual entries.

=head3 Example

    '1-5,16-20,23'
    
becomes

    [1,2,3,4,5,16,17.18.19.20.23]

=head3 Parameters

    * entries. String
    
=head3 Returns

    * An array ref of scheduled times

=cut

    sub expand_entries {
        my $entries = shift;
        $entries =~ s/\s+//g;
        my @entries = split /,/, $entries;
        my @entry_list;
    
        foreach my $entry (@entries) {
            if ($entry =~ /^(\d{1,2})-(\d{1,2})$/) {
                my ($lower, $upper) = ($1, $2);
    
                if ($lower < $upper) {
                    for my $counter ($lower .. $upper) {
                        push @entry_list, $counter;
                    }
                } else {
                    push @entry_list, $entry;
                }
            } else {
                push @entry_list, $entry;
            }
        }
    
        return @entry_list;
    }
    
=head2 expand_days_of_week

Similar to C<expand_entries>, Takes section of cron entries for
the day of the week. Cron expects entries to run from Sun (0) t0
Sat (6). Our input runs from (1-7) so we simply subtact 1 from each
entry

=head3 Example

    '1-5,16-20,23'
    
becomes

    [1,2,3,4,5,16,17,18,19,20,23]

=head3 Parameters

    * entries. String
    
=head3 Returns

    * A an arrarey of day elements

=cut

    sub expand_days_of_week {
        my @entry_list = expand_entries(shift);
    
        foreach my $entry (@entry_list) {
            $entry-- if ($entry =~ /^\d+$/);
        }
    
        return @entry_list;
    }

=head2 validate_entries

Takes a list of entries (Comma-separated values), and makes sure that each
element is valid. The rules are

    * each element must consist of one or two digits
    * each element must be greater than the previous one
    * no entry can be greater than the limit for the type of entry
      (e.g. minutes cannot be greater than 59, and hours can't
       be greater than 23)

=head3 Parameters

An array consisting of the following entries:

    * entries. Mandatory. A string of comma-delimited entries
    * upper_limit. Mandatory. The maximum value allowed
    * zero_allowed. Optional. Whether or not 0 is a valid element for
      this type of entry
    
=head3 Returns

    * 1 (valid) or 0 (invalid)

=cut

    sub validate_entries {
        my $entries     = shift || die 'No entries to validate';
        my $upper_limit = shift || die 'No upper limit';
    
        # Can 0 be a valid entry?
        my $zero_allowed = shift || 0;
        my $lower_value = -1;
    
        my @expanded_entries = @$entries;
        foreach my $entry (@expanded_entries) {
            if ($entry =~ /^(\d{1,2})$/) {
                my $entry = $1;
    
                if (($entry == 0) && (!$zero_allowed)) {
                    return 0;
                }
    
                if ($entry > $lower_value) {
                    $lower_value = $entry;
                } else {
                    return 0;
                }
    
                if ($entry > $upper_limit) {
                    return 0;
                }
            } else {
                return 0;
            }
        }
    
        return 1;
    }

=head2 validate_hours

Validates the cron entries for hours

=head3 Parameters

    * entries. Mandatory. A string of comma-delimited entries
    
=head3 Returns

    * 1 (valid) or 0 (invalid)

=cut

    method validate_hours(Str $hours) {
        return validate_entries([expand_entries($hours)], 23, 1);
    }

=head2 validate_minutes

Validates the cron entries for minutes

=head3 Parameters

    * entries. Mandatory. A string of comma-delimited entries
    
=head3 Returns

    * 1 (valid) or 0 (invalid)

=cut

    method validate_minutes(Str $minutes) {
        return validate_entries([expand_entries($minutes)], 59, 1);
    }

=head2 validate_days_of_week

Validates the cron entries for days of the week

=head3 Parameters

    * entries. Mandatory. A string of comma-delimited entries
    
=head3 Returns

    * 1 (valid) or 0 (invalid)

=cut

    method validate_days_of_week(Str $dow) {
        return validate_entries([expand_days_of_week($dow)], 6, 1);
    }

=head2 validate_days_of_month

Validates the cron entries for days of the month

=head3 Parameters

    * entries. Mandatory. A string of comma-delimited entries
    
=head3 Returns

    * 1 (valid) or 0 (invalid)

=cut

    method validate_days_of_month(Str $dom) {
        return validate_entries([expand_entries($dom)], 31);
    }

=head2 validate_months

Validates the cron entries for the month entries

=head3 Parameters

    * entries. Mandatory. A string of comma-delimited entries
    
=head3 Returns

    * 1 (valid) or 0 (invalid)

=cut

    method validate_months(Str $months) {
        return validate_entries([expand_entries($months)], 12);
    }

=head2 contract_entries

Takes an array ref of cron entries and turns them back into
a cron string. Consectutive values are turned into ranges, i.e.

    [1,4,5,6,10]
    
Becomes

    '1,4-6,10'

=head3 Parameters

    * entries. Mandatory. A string of comma-delimited entries
    
=head3 Returns

    * 1 (valid) or 0 (invalid)

=cut

    sub contract_entries {
        my $entries = shift || die "No entries to concatenate";
        my $low_value;
        my @new_entries;
        my $grouping = 0;
    
        foreach my $idx (0 .. @$entries - 1) {
            if ($grouping) {
                if ($entries->[$idx] != ($entries->[$idx - 1] + 1)) {
                    $grouping = 0;
                    push @new_entries, $low_value . '-' . $entries->[$idx - 1];
                    $low_value = undef;
                }
            }
    
            if ($idx <= @$entries - 2) {
                if (!$grouping) {
                    if (($entries->[$idx] + 1) == $entries->[$idx + 1]) {
                        $grouping  = 1;
                        $low_value = $entries->[$idx];
                    } else {
                        push @new_entries, $entries->[$idx] if !$grouping;
                    }
                }
            } elsif ($idx == @$entries - 1) {
                if ($grouping) {
                    push @new_entries, $low_value . '-' . $entries->[$idx];
                } else {
                    push @new_entries, $entries->[$idx];
                }
            }
        }
    
        return join(',', @new_entries);
    }

=head2 get_contracted_doms

Returns the days of month cron string for a given schedule.

=head3 Parameters

    * schedule_id. Integer. Optional. The primary key of the schedule
    
=head3 Returns

    * cron entry string

=cut

    method get_contracted_doms(Maybe[Int] $schedule_id?) {
        my $doms_rs     = $self->get_schedule_doms($schedule_id);
        my (@schedule_doms, $dom_ids);
    
        while (my $dom = $doms_rs->next) {
            push @schedule_doms, $dom->schedule_dom;
        }
    
        $self->logger->debug(Dumper(\@schedule_doms));
    
        return contract_entries(\@schedule_doms);
    }

=head2 get_contracted_cron_dows

Returns the days of the week cron string for a given schedule.

=head3 Parameters

    * schedule_id. Integer. Optional. The primary key of the schedule
    
=head3 Returns

    * cron entry string

=cut

    method get_contracted_cron_dows(Maybe[Int] $schedule_id?) {
        my $dows = [sort keys %{$self->get_schedule_cron_dows($schedule_id)}];
        return contract_entries($dows);
    }
    
=head2 get_contracted_hours

Returns thehours of execution cron string for a given schedule.

=head3 Parameters

    * schedule_id. Integer. Optional. The primary key of the schedule
    
=head3 Returns

    * cron entry string

=cut

    method get_contracted_hours(Maybe[Int] $schedule_id?) {
        my $hours_rs    = $self->get_schedule_hours($schedule_id);
        my (@schedule_hours, $hour_ids);
    
        while (my $hour = $hours_rs->next) {
            push @schedule_hours, $hour->schedule_hour;
        }
    
        $self->logger->debug(Dumper(\@schedule_hours));
    
        return contract_entries(\@schedule_hours);
    }

=head2 get_contracted_minutes

Returns the minutes of execution cron string for a given schedule.

=head3 Parameters

    * schedule_id. Integer. Optional. The primary key of the schedule
    
=head3 Returns

    * cron entry string

=cut

    method get_contracted_minutes(Maybe[Int] $schedule_id?) {
        my $minutes_rs  = $self->get_schedule_minutes($schedule_id);
        my (@schedule_minutes, $minute_ids);
    
        while (my $minute = $minutes_rs->next) {
            push @schedule_minutes, $minute->schedule_minute;
        }
    
        $self->logger->debug(Dumper(\@schedule_minutes));
    
        return contract_entries(\@schedule_minutes);
    }
    
=head2 save

Saves the schedule to the database

=head3 Parameters

    * params. A hashref of containing the schedule data
    
=head3 Returns

    * Void

=cut

    method save (HashRef $params) {
        my $schedule;
    
        $self->logger->debug(Dumper($params));
        $params->{status} = 0 unless $params->{status};
    
        $self->logger->debug("Getting the date");
        my $date = $self->now;
        $self->logger->debug("Got the date");
        
        $self->logger->debug('schema: ' . ref($self->schema));
    
        try{
            $self->schema->txn_do(
                sub {
                    # If we were supplied a schedule id then we update an existing
                    # schedule
        
                    $self->logger->debug('Getting config record');
        
                    my $config = $self->EtlpConfiguration->single(
                        {config_name => $params->{config_file}});
        
                    $self->logger->debug('Got config record or a null');
        
                    unless ($config) {
                        $self->logger->debug('Creating a config record');
                        $config = $self->EtlpConfiguration->create(
                            {
                                config_name  => $params->{config_file},
                                date_created => $date,
                                date_updated => $date,
                            }
                        );
                        $self->logger->debug('Created a config record');
                    }
        
                    $self->logger->debug("Config: " . $config->config_id);
        
                    my $section = $self->EtlpSection->single(
                        {
                            section_name => $params->{section},
                            config_id    => $config->config_id
                        }
                    );
        
                    unless ($section) {
                        $section = $self->EtlpSection->create(
                            {
                                section_name => $params->{section},
                                config_id    => $config->config_id,
                                date_created => $date,
                                date_updated => $date,
                            }
                        );
                    }
        
                    my $section_id = $section->section_id;
                    $self->logger->debug("Section: " . $section_id);
        
                    if ($params->{schedule_id}) {
                        $self->logger->debug(
                            'Updating the schedule ' . $params->{schedule_id});
                        $schedule = $self->EtlpSchedule->single(
                            {schedule_id => $params->{schedule_id}});
        
                        $schedule->update(
                            {
                                'schedule_description' =>
                                  $params->{schedule_description},
                                'schedule_comment' => $params->{schedule_comment},
                                'status'           => $params->{status},
                                'user_updated'     => $params->{user_id},
                                'date_updated'     => $date,
                                'section_id'       => $section_id,
                            }
                        );
                        $self->logger->debug('Schedule updated');
                    } else {
                        # create a new schedule
                        $self->logger->debug('Creating a new schedule');
                        $schedule = $self->EtlpSchedule->create(
                            {
                                schedule_description => $params->{schedule_description},
                                schedule_comment     => $params->{schedule_comment},
                                status               => $params->{status},
                                user_created         => $params->{'user_id'},
                                user_updated         => $params->{'user_id'},
                                date_created         => $date,
                                date_updated         => $date,
                                section_id           => $section->section_id,
                            }
                        );
                    }
        
                    my $schedule_id = $schedule->schedule_id;
                    # Delete old minutes and add new ones
                    my $minutes = $self->EtlpScheduleMinute->search(
                        {schedule_id => $schedule->schedule_id});
                    $minutes->delete_all;
        
                    $self->EtlpScheduleMinute->populate(
                        [
                            [qw/schedule_id schedule_minute/],
                            map { [$schedule_id, $_] }
                              expand_entries($params->{schedule_minutes})
                        ]
                    ) if defined $params->{schedule_minutes};
        
                    # Delete old hours and add new ones
                    my $hours = $self->EtlpScheduleHour->search(
                        {schedule_id => $schedule->schedule_id});
                    $hours->delete_all;
                    $self->EtlpScheduleHour->populate(
                        [
                            [qw/schedule_id schedule_hour/],
                            map { [$schedule_id, $_] }
                              expand_entries($params->{schedule_hours})
                        ]
                    ) if defined $params->{schedule_hours};
        
                    # Delete old days of month and add new ones
                    my $doms = $self->EtlpScheduleDayOfMonth->search(
                        {schedule_id => $schedule->schedule_id});
                    $doms->delete_all;
                    $self->EtlpScheduleDayOfMonth->populate(
                        [
                            [qw/schedule_id schedule_dom/],
                            map { [$schedule_id, $_] }
                              expand_entries($params->{schedule_doms})
                        ]
                    ) if defined $params->{schedule_doms};
        
                    # This relies on the fact that there is only one schedule month
                    # record, although the data model allows for an arbitrary number
                    my $month = $self->EtlpScheduleMonth->search(
                        {schedule_id => $schedule->schedule_id})->first;
        
                    # If we received a month
                    if (defined $params->{month_id}) {
                        # if we have a month record then update it...
                        if (defined $month) {
                            $month->month_id($params->{month_id});
                            $month->update;
                        }
                        # ... else create its
                        else {
                            $month = $self->EtlpScheduleMonth->create(
                                {
                                    schedule_id => $schedule_id,
                                    month_id    => $params->{month_id}
                                }
                            );
                        }
                    }
                    # ... else delete any existing month
                    else {
                        $self->EtlpScheduleMonth->search(
                            {schedule_id => $schedule->schedule_id})->delete_all();
                    }
        
                    if (ref $params->{dow_id} ne 'ARRAY') {
                        $params->{dow_id} = [$params->{dow_id}];
                    }
        
                    $self->logger->debug('dow_id: ', Dumper($params->{dow_id}));
        
                    # Delete old days of the week and add new ones
                    $self->EtlpScheduleDayOfWeek->search(
                        {schedule_id => $schedule->schedule_id})->delete_all();
        
                    if (defined $params->{dow_id}->[0]) {
                        $self->EtlpScheduleDayOfWeek->populate(
                            [
                                [qw/schedule_id dow_id/],
                                map { [$schedule_id, $_] } @{$params->{dow_id}}
                            ]
                        );
                    }
        
                }
            );
        } catch {
            $self->logger->logdie($_);
        };
        return $schedule->schedule_id;
    }
    
=head2 get_scheduler_status

Sets the scheduler status

=head3 Parameters

None
    
=head3 Returns

    * An ep_app_config DBIx::Class row

=cut

    method get_scheduler_status {
        return $self->EtlpAppConfig->single({'parameter' => 'scheduler status'});
    }
    
=head2 generate_crontab

Generates a crontab from the database schedues

=head3 Parameters

    * pipeline script. String. Full path to the etl-pipeline script
    
=head3 Returns

    * crontab as a string

=cut

    method generate_crontab($pipeline_script) {
        my $wrapper         = Text::Wrapper->new(columns => 70);
    
        my $schedule_status = $self->get_scheduler_status();
    
        my $crontab = <<EOT;
# WARNING: This file was generated by ETLp. DO not edit by hand
# or your changes will be lost
#
#             field          allowed values
#             =============  =================================
#             minute         0-59
#             hour           0-23
#             day of month   1-31
#             month          1-12 (or names, see below)
#             day of week    0-7 (0 or 7 is Sun, or use names)
#
EOT
    
        foreach my $schedule (@{$self->get_schedule_details({no_paging => 1})}) {
            if ($schedule->{description}) {
                # Wrap the description at 60 columns
                my @descriptions = split /\n/, $schedule->{description};
    
                foreach my $description (@descriptions) {
                    $description = $wrapper->wrap($description);
                    $description =~ s/^/# /mg;
                }
    
                $schedule->{description} = join("\n", @descriptions);
                $schedule->{description} =~ s/\n+/\n/g;
                $crontab .= $schedule->{description};
            }
    
            $crontab .= '#' unless ($schedule_status->value() eq 'enabled');
            $crontab .= '#' unless $schedule->{status};
            $schedule->{minutes}  = '*' unless $schedule->{minutes}  =~ /\d/;
            $schedule->{hours}    = '*' unless $schedule->{hours}    =~ /\d/;
            $schedule->{doms}     = '*' unless $schedule->{doms}     =~ /\d/;
            $schedule->{month_id} = '*' unless $schedule->{month_id} =~ /\d/;
            $schedule->{day_ids}  = '*' unless $schedule->{day_ids}  =~ /\d/;
    
            $crontab .= sprintf(
                "%s %s %s %s %s $pipeline_script %s %s\n",
                $schedule->{minutes}, $schedule->{hours},
                $schedule->{doms},    $schedule->{month_id},
                $schedule->{day_ids}, $schedule->{config_name},
                $schedule->{section_name}
            );
        }
    
        return $crontab;
    
    }
    
=head2 get_config_files

Get a list of configuration files in the application configuration
directory

=head3 Parameters

    * config_dir. String. Mandatory. The directory that stores the config files
    
=head3 Returns

    * An array ref of configuration files

=cut

    method get_config_files (Maybe[Str] $config_dir?) {
        my @configuration_files;
    
        opendir(my $dir, $config_dir)
          || $self->logger->logdie("Cannot open $config_dir");
    
        while (defined(my $file = readdir($dir))) {
            next unless -f $config_dir . '/' . $file;
            next if $file eq 'env.conf';
            if ($file =~ /^(.*)\.conf$/) {
                push @configuration_files, $1;
            }
        }
    
        return [sort @configuration_files];
    }

=head2 set_scheduler_status

Sets the scheduler status

=head3 Parameters

A string

    * The scheduler status
    
=head3 Returns

    * Void

=cut

    method set_scheduler_status(Str $status) {
        my $schedule_status = $self->get_scheduler_status;
        $schedule_status->update({value => $status});
    }

=head2 get_sections

Get all of the sections in a configurations file

=head3 Parameters

    * configuration file. String. The *full* path to the configuration file
    
=head3 Returns

    * An array ref of sections

=cut

    method get_sections(Str $configuration_file) {
        $configuration_file .= '.conf';
    
        my %config = ParseConfig(-ConfigFile => $configuration_file,);
        return [sort(keys %config)];
    }

=head2 get_job

Given a schedule (an EPSection record), returns the job (configuration
file name, section name)

=head3 Parameters

    * configuration file. String. The *full* path to the configuration file
    
=head3 Returns

    * An array; config name, section name

=cut

    method get_job($schedule) {
        return ($schedule->section->ep_config->config_name,
            $schedule->section->section_name);
    }

=head2 get_section_options

Given a config file, return the list of sections - each element
will apear in HTML option tags

=head3 Parameters

    * configuration file. String. The configuration file name
    
=head3 Returns

    * An HTML string

=cut

    method get_section_options(HashRef $args) {
        my $app_conf_dir = $args->{app_conf_dir};
        my $config_file  = $args->{config_file};
        my $show_blank   = $args->{show_blank};
        my $sections     = $self->get_sections($app_conf_dir . '/' . $config_file);
        my $options;
    
        my $counter = 1;
    
        if ($show_blank) {
            $options = '<option selected="selected"></option>';
        }
    
        foreach my $section (@$sections) {
            if (($counter++ == 1) && !($show_blank)) {
                $options .=
    qq{<option value="$section" selected="selected">$section</option>};
            } else {
                $options .= qq{<option value="$section">$section</option>};
            }
        }
    
        return $options;
    }

=head2 config_exists

Determines whether a configuration file exists

=head3 Parameters

    * configuration file. String. The pull path to the configuration
      file name, excluding the .conf extension
    
=head3 Returns

    * 1 = true, 0 = false

=cut

    method config_exists(Str $config_file) {
        return (-f $config_file . '.conf') ? 1 : 0;
    }

=head2 delete

Deletes a schedule, and dependent records

=head3 Parameters

    * schedule_id. Integer. The surrogate key for the schedule
    
=head3 Returns

    * Void

=cut

    method delete(Int $schedule_id) {
        my $schedule_rs = $self->EtlpSchedule->search(schedule_id => $schedule_id);
        my $minutes_rs =
          $self->EtlpScheduleMinute->search({schedule_id => $schedule_id});
        my $hours_rs = $self->EtlpScheduleHour->search({schedule_id => $schedule_id});
        my $dow_rs =
          $self->EtlpScheduleDayOfWeek->search({schedule_id => $schedule_id});
        my $dom_rs =
          $self->EtlpScheduleDayOfMonth->search({schedule_id => $schedule_id});
        my $month_rs =
          $self->EtlpScheduleMonth->search({schedule_id => $schedule_id});
    
        $self->schema->txn_do(
            sub {
                $month_rs->delete_all;
                $dom_rs->delete_all;
                $dow_rs->delete_all;
                $hours_rs->delete_all;
                $minutes_rs->delete_all;
                $schedule_rs->delete_all;
            }
        );
    }

=head2 get_dependencies

Returns the last of dependent jobs as specified by the "next" parameter
in the application config.

=head3 Parameters

A hashref:

    * config_dir. String. The directory where the configuration files
      are found
    * config_file. String. The root config file
    * section. The section on the config file that we wish to derive
      the dependencies from
    
=head3 Returns

    * dependencies as an array

=cut

    method get_dependencies(Str :$config_dir, Str :$config_file, Str :$section) {
        my @dependencies;
    
        $config_file .= '.conf' unless $config_file =~ /\.conf$/;
        $config_file = $config_dir . '/' . $config_file;
    
        my %config = ParseConfig(-ConfigFile => $config_file,);
        if ($config{$section}->{config}->{next}) {
            my ($new_config_file, $new_section) = split /\s+/,
              $config{$section}->{config}->{next};
            push @dependencies, $config{$section}->{config}->{next},
              $self->get_dependencies(
                #{
                    config_dir  => $config_dir,
                    config_file => $new_config_file,
                    section     => $new_section
                #}
              );
        }
    
        return @dependencies;
    }
}
     
