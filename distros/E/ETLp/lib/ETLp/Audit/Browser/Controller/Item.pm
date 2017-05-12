use MooseX::Declare;

class ETLp::Audit::Browser::Controller::Item extends ETLp::Audit::Browser::Controller::Base {
    
    method list {
        my $q          = $self->query;
        my $job_id     = $q->param('job_id')  || undef;
        my $item_id    = $q->param('item_id') || undef;
        my $status_id  = $q->param('status_id') || undef;
        my $item_name  = $q->param('item_name') || undef;
        my $filename   = $q->param('filename') || undef;
        my $page       = $q->param('page') || 1;
    
        my $status_list    = $self->model->get_status_list;
        my $item_name_list = $self->model->get_item_name_list($job_id);
    
        my $items = $self->model->get_items(
                job_id     => $job_id,
                item_id    => $item_id,
                status_id  => $status_id,
                item_name  => $item_name,
                filename   => $filename,
                page       => $page
        );
            
        return $self->tt_process(
            {
                items          => $items,
                item_id        => $item_id,
                status_id      => $status_id,
                item_name      => $item_name,
                filename       => $filename,
                item_name_list => $item_name_list,
                status_list    => $status_list,
                job_id         => $job_id,
            }
        );
    }
    
    method setup {
        $self->start_mode('list');
        $self->run_modes([qw/list error/]);
    }
    
    method module {
        return 'Items';
    }
    
}