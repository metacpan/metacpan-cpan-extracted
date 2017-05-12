package ETLp::Audit::Browser::Controller::Schedule;
use Moose;
extends 'ETLp::Audit::Browser::Controller::Base';
use CGI::Application::Plugin::ValidateRM (qw/check_rm/);
use Data::Dumper;

sub list {
    my $self         = shift;
    my $q            = $self->query;
    my $config_name  = $q->param('config_name');
    my $section_name = $q->param('section_name');
    my $status       = $q->param('status');
    my $page         = $q->param('page') || 1;
    my $sections;

    $self->logger->debug("Looking for schedules");
    my $schedules = $self->model->get_schedule_details(
        {
            config_name  => $config_name,
            section_name => $section_name,
            status       => $status,
            page         => $page,
            no_paging    => 1
        }
    );
    $self->logger->debug("Got schedules");

    my $scheduler_status = $self->model->get_scheduler_status;

    my $config_files =
      $self->model->get_config_files($self->conf->param('app_conf_dir'));

    if ($config_name) {
        $sections =
          $self->model->get_sections(
            $self->conf->param('app_conf_dir') . '/' . $config_name);
    }

    return $self->tt_process(
        {
            schedules        => $schedules,
            config_files     => $config_files,
            config_name      => $config_name,
            section_name     => $section_name,
            sections         => $sections,
            status           => $status,
            scheduler_status => $scheduler_status
        }
    );
}

# Form for editing a schedule
sub edit {
    my $self = shift;
    my $errs = shift;
    my $q    = $self->query;
    my ($config, $section, $sections, $dependencies);

    my $schedule_id      = $q->param('schedule_id') || undef;
    my $schedule         = $self->model->get_schedule($schedule_id);
    my $months           = $self->model->get_months;
    my $dows             = $self->model->get_dows;
    my $schedule_month   = $self->model->get_schedule_month($schedule_id);
    my $schedule_dows    = $self->model->get_schedule_dows($schedule_id);
    my $schedule_doms    = $self->model->get_contracted_doms($schedule_id);
    my $schedule_minutes = $self->model->get_contracted_minutes($schedule_id);
    my $schedule_hours   = $self->model->get_contracted_hours($schedule_id);
    my $config_files =
        $self->model->get_config_files($self->conf->param('app_conf_dir'));

    $self->logger->debug('Available config files: ' . Dumper($config_files));
    
    $dependencies = [];

    if ($schedule) {
        ($config, $section) = $self->model->get_job($schedule);

        $self->logger->debug("Config: $config");
        $self->logger->debug("Section: $section");

        $sections =
          $self->model->get_sections(
            $self->conf->param('app_conf_dir') . '/' . $config);

        $self->logger->debug('Sections: ' . Dumper($sections));
        $dependencies = [
            $self->model->get_dependencies(
                #{
                    config_dir  => $self->conf->param('app_conf_dir'),
                    config_file => $config,
                    section     => $section
                #}
            )
        ];
    } else {
        if (@$config_files > 0) {
            $sections =
              $self->model->get_sections(
                $self->conf->param('app_conf_dir') . '/' . $config_files->[0]);
            $config = $config_files->[0] unless $config;

            if (@$sections > 0) {
                $dependencies = [
                    $self->model->get_dependencies(
                        #{
                            config_dir  => $self->conf->param('app_conf_dir'),
                            config_file => $config,
                            section     => $sections->[0],
                        #}
                    )
                ];
            }
        }
    }

    return $self->tt_process(
        {
            schedule         => $schedule,
            months           => $months,
            dows             => $dows,
            schedule_month   => $schedule_month,
            schedule_dows    => $schedule_dows,
            schedule_doms    => $schedule_doms,
            schedule_minutes => $schedule_minutes,
            schedule_hours   => $schedule_hours,
            config           => $config,
            section          => $section,
            config_files     => $config_files,
            sections         => $sections,
            dependencies     => join(' -&gt; ', @$dependencies),
            errs             => $errs,
        }
    );
}

# Save the schedule
sub save {
    my $self = shift;

    # validate user input
    my ($results, $err_page) = $self->check_rm('edit', '_schedule_profile');
    return $err_page if ($err_page);

    my $q = $results->valid;

    my $crontab_file =
        $self->conf->param('crontab_publish_dir') . '/'
      . $self->conf->param('crontab_owner');
    my $pipeline_script = $self->conf->param('pipeline_script');

    if ($q->{'delete'}) {
        $self->model->delete($q->{schedule_id});
        $self->model->publish_crontab(
            {
                crontab_file    => $crontab_file,
                pipeline_script => $pipeline_script
            }
        );
        return $self->redirect($self->conf->param('root_url') . '/schedule');
    }

    # We've concatenated the config file name to the section name to ensure
    # that the section name is unique across config files (so that the
    # Javascript onChange event would fire if an Ajax call updated a section
    # with the same section name from a different config). However, we now need
    # to strip the config_file off again
    my $config_file = $q->{config_file};
    if ($q->{section} =~ /^$config_file\-(.*)$/) {
        $q->{section} = $1;
    }

    $q->{user_id} = $self->session->param('user_id');

    $self->logger->debug(Dumper($q));
    my $schedule_id = $self->model->save($q);

    $self->logger->debug("Crontab file: $crontab_file");
    $self->logger->debug("Pipeline script: $pipeline_script");

    #$self->model->publish_crontab(
    #    {crontab_file => $crontab_file, pipeline_script => $pipeline_script});

    if ($q->{schedule_id}) {
        $self->session->param('message', 'Schedule Updated');
    } else {
        $self->session->param('message', 'Schedule Created');
    }

    return $self->redirect(
        $self->conf->param('root_url') . '/schedule/edit/' . $schedule_id);
}

# Process ajax call to update the section list drop down if the config item
# changes
sub update_sections {
    my $self        = shift;
    my $config_file = $self->query->param('config_file');
    my $show_blank  = $self->query->param('show_blank') || 0;
    
    return $self->model->get_section_options(
        {
            app_conf_dir => $self->conf->param('app_conf_dir'),
            config_file  => $config_file,
            show_blank   => $show_blank
        }
    );
}

# Return the crontab from the database
sub view_crontab {
    my $self = shift;
    my $crontab =
      $self->model->generate_crontab($self->conf->param('pipeline_script'));
    return $self->tt_process({crontab => $crontab});
}

# Disable the entire crontab
sub disable_crontabe {
    my $self = shift;
    return $self->_set_crontab_status('disabled');
}

# Enable the entire crontab
sub enable_crontab  {
    my $self = shift;
    return $self->_set_crontab_status('enabled');
}

sub _set_crontab_status {
    my $self   = shift;
    my $status = shift;

    my $crontab_file =
        $self->conf->param('crontab_publish_dir') . '/'
      . $self->conf->param('crontab_owner');

    my $pipeline_script = $self->conf->param('pipeline_script');

    # save the status to the database
    $self->model->set_scheduler_status($status);

    $self->logger->debug("Publishing the crontab");
    # Publish the crontab now that the status has changed
    $self->model->publish_crontab(
        {crontab_file => $crontab_file, pipeline_script => $pipeline_script});

    return $self->redirect($self->conf->param('root_url') . '/schedule/');
}

# This runmode is used to return the chain of pipelines dependent on the one
# provided
sub update_dependencies {
    my $self        = shift;
    my $config_file = $self->query->param('config');
    my $section     = $self->query->param('section');

    if ($section =~ /^$config_file\-(.*)$/) {
        $section = $1;
    }

    return join(
        ' -&gt; ',
        $self->model->get_dependencies(
            #{
                config_dir  => $self->conf->param('app_conf_dir'),
                config_file => $config_file,
                section     => $section
            #}
        )
    );
}

sub module {
    return 'Schedules';
}

# This is a validation profile that checks the user inut for a schedule.
# Refer to http://search.cpan.org/dist/Data-FormValidator for documentation
# of its syntax
sub _schedule_profile {
    my $self = shift;
    return {
        required => [qw/schedule_description config_file section/],
        optional => [
            qw/schedule_comment dow_id schedule_hours schedule_minutes status
              schedule_dom_id month_id schedule_doms schedule_id delete/
        ],
        constraints => {
            dow_id => sub {
                return $self->model->validate_days_of_week(shift);
            },
            schedule_hours => sub {
                return $self->model->validate_hours(shift);
            },
            schedule_minutes => sub {
                return $self->model->validate_minutes(shift);
            },
            status          => qr/^1$/,
            schedule_dom_id => sub {
                return $self->model->validate_days_of_month(shift);
            },
            schedule_doms => sub {
                return $self->model->validate_days_of_month(shift);
            },
            schedule_id => qr/^\d+$/,
            month_id    => qr/^\d+$/,
            delete      => qr/^Delete$/,
            config_file => [
                # Check that the config file exists
                {
                    name       => 'no_config',
                    constraint => sub {
                        my ($self, $config_file) = @_;
                        $config_file =
                            $self->conf->param('app_conf_dir') . '/'
                          . $config_file;
                        return $self->model->config_exists($config_file);
                    },
                    params => [$self, 'config_file']
                },
                # Ensure that the section actually exists in the config file
                {
                    name       => 'no_section',
                    constraint => sub {
                        my ($self, $config_file, $section) = @_;

                        # Remove the prefixed config name from the section name
                        if ($section =~ /^$config_file\-(.*)$/) {
                            $section = $1;
                        }

                        $config_file =
                            $self->conf->param('app_conf_dir') . '/'
                          . $config_file;
                        # There's no point in continuing unless the config file
                        # exists. But the check above raises the error so we
                        # will return 1 (true) if it doesn't. We don't want to
                        # return two errors for the same thing
                        return 1
                          unless ($self->model->config_exists($config_file));

                        my $sections = $self->model->get_sections($config_file);
                        return grep(/^$section$/, @$sections) ? 1 : 0;
                    },
                    params => [$self, qw/config_file section/]
                }
            ]
        },
        msgs => {
            any_errors  => 'some_errors',
            constraints => {
                no_config  => 'The config file does not exist',
                no_section => 'The section is not on the config file',
            }
        }
    };
}

sub setup {
    my $self = shift;
    $self->start_mode('list');
    $self->run_modes(
        [
            qw/list edit save update_sections view_crontab
                disable_crontab enable_crontab update_dependencies/
        ]
    );
}
1;