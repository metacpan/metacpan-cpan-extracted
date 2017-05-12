use MooseX::Declare;

class ETLp::Audit::Browser::Controller::Job extends ETLp::Audit::Browser::Controller::Base {
    
    method list {
        my $page         = $self->query->param('page') || 1;
        my $config_id    = $self->query->param('config_id') || undef;
        my $section_name = $self->query->param('section_name') || undef;
        my $minimum_date = $self->query->param('minimum_date') || undef;
        my $maximum_date = $self->query->param('maximum_date') || undef;
        my $status_id    = $self->query->param('status_id') ||undef;
    
        # The processes that the user is viewing
        my $jobs = $self->model->get_jobs(
            #{
                page         => $page,
                config_id    => $config_id,
                section_name => $section_name,
                minimum_date => $minimum_date,
                maximum_date => $maximum_date,
                status_id    => $status_id,
            #}
        );
    
        # The configuration and section drop_down lists
        my $config_list  = $self->model->get_config_list();
        my $section_list = $self->model->get_section_list($config_id);
        my $status_list  = $self->model->get_status_list;
    
        $self->logger->debug("Config list: " . ref($config_list));
        $self->logger->debug("Section list: " . ref($section_list));
    
        return $self->tt_process(
            {
                jobs         => $jobs,
                minimum_date => $minimum_date,
                maximum_date => $maximum_date,
                config_list  => $config_list,
                section_list => $section_list,
                status_list  => $status_list,
                config_id    => $config_id,
                status_id    => $status_id,
                section_name => $section_name,
                header_inc   => 'process_inc.tmpl',
            }
        );
    }
    
    method update_sections {
        my $config_id = $self->query->param('config_id') || undef;
        return $self->model->get_config_section_options($config_id);
    }
    
    # Ajax call - when a user selects a section from the drop down list,
    # return the configurations that it belongs to it in HTML '<option>' tags
    method update_configs {
        my $section_name = $self->query->param('section_name') || undef;
        return $self->model->get_section_config_options($section_name);
    }
    
    method setup {
        $self->start_mode('list');
        $self->run_modes([qw/list update_sections update_configs error/]);
    }
    
    method module {
        return 'Processes';
    }
}