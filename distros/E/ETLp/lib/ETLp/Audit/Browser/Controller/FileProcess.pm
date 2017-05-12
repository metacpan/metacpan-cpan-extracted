use MooseX::Declare;

class ETLp::Audit::Browser::Controller::FileProcess extends ETLp::Audit::Browser::Controller::Base {
    
    method list {
        my $q       = $self->query;
        my $item_id = $q->param('item_id') || undef;
        my $file_id = $q->param('file_id') || undef;
        my $page    = $q->param('page') || 1;
        my $canonical_file;
    
        if ($file_id) {
            $canonical_file = $self->model->get_canonical_file($file_id);
        }
    
        my $file_processes = $self->model->get_file_processes(
            file_id => $file_id, item_id => $item_id, page => $page);
        return $self->tt_process(
            {canonical_file => $canonical_file, file_processes => $file_processes});
    }
    
    method setup {
        $self->start_mode('list');
        $self->run_modes([qw/list error/]);
    }
    
    method module {
        return 'File Process';
    }
    
}